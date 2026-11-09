# Isolated hosted-runner smoke test, never intended for an end-user machine.
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_OS -ne 'Windows') {
  throw 'This destructive smoke test is restricted to GitHub Windows runners.'
}
$setup = Join-Path $PWD 'artifacts/Nexus-AI-Setup.exe'
$app = Join-Path $env:LOCALAPPDATA 'Programs/Nexus AI'
$data = Join-Path $env:LOCALAPPDATA 'NexusAI'
$registry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{A42A3B2D-7E91-4B61-9D1A-7C2B7A9F0D31}_is1'
if ((Test-Path $app) -or (Test-Path $data) -or (Test-Path $registry)) {
  throw 'Runner already has Nexus AI files; refusing to overwrite them.'
}
$log = Join-Path $PWD 'ci-logs'
function Invoke-Setup([string] $Suffix, [string[]] $Extra = @()) {
  $args = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', '/CURRENTUSER',
    "/LOG=`"$log/install-$Suffix.txt`"") + $Extra
  $p = Start-Process -FilePath $setup -ArgumentList $args -PassThru
  if (-not $p.WaitForExit(120000)) { throw 'Setup timed out.' }
  if ($p.ExitCode -ne 0) { throw "Setup $Suffix exit code $($p.ExitCode)" }
}
function Assert-State {
  if ((Get-FileHash "$data/user-state.json" -Algorithm SHA256).Hash -ne $script:stateHash) {
    throw 'User-state checkpoint was changed/deleted by installation or uninstall.'
  }
}
function Wait-App {
  $deadline = [DateTime]::UtcNow.AddSeconds(30)
  do {
    $p = Get-Process nexus_ai -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p -and $p.MainWindowHandle -ne 0) { return $p }
    Start-Sleep -Milliseconds 250
  } while ([DateTime]::UtcNow -lt $deadline)
  throw 'Installed app did not create a native window within 30 seconds.'
}
function Close-App($p) {
  if (-not $p.CloseMainWindow()) { throw 'Native close request rejected.' }
  if (-not $p.WaitForExit(15000)) { throw 'App did not exit after native close.' }
  if ($p.ExitCode -ne 0) { throw "Application exited with $($p.ExitCode)" }
}
try {
  New-Item -ItemType Directory $data | Out-Null
  # Valid checkpoint, not fabricated screenshots or a claim of UI editing.
  @{
    schema = 1
    settings = @{ floating = $true; orbital = $true; glow = 0.82; reduced = $false;
      palette = 'neonViolet'; model = 'audit-sentinel' }
    conversations = @()
  } | ConvertTo-Json -Depth 8 | Set-Content "$data/user-state.json" -Encoding utf8NoBOM
  $script:stateHash = (Get-FileHash "$data/user-state.json" -Algorithm SHA256).Hash
  Invoke-Setup 'first' @('/TASKS=desktopicon')
  foreach ($file in @('nexus_ai.exe', 'flutter_windows.dll', 'msvcp140.dll',
      'vcruntime140.dll', 'vcruntime140_1.dll', 'data/app.so', 'unins000.exe')) {
    if (-not (Test-Path (Join-Path $app $file))) { throw "Installed file missing: $file" }
  }
  $entry = Get-ItemProperty $registry
  if ($entry.DisplayVersion -ne $env:NEXUS_VERSION) { throw 'Uninstall registry version mismatch.' }
  $start = Join-Path ([Environment]::GetFolderPath('Programs')) 'Nexus AI/Nexus AI.lnk'
  $desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Nexus AI.lnk'
  $shell = New-Object -ComObject WScript.Shell
  foreach ($link in @($start, $desktop)) {
    if (-not (Test-Path $link)) { throw "Shortcut missing: $link" }
    if ($shell.CreateShortcut($link).TargetPath -ne (Join-Path $app 'nexus_ai.exe')) {
      throw "Wrong shortcut target: $link"
    }
  }
  $version = (Get-Item "$app/nexus_ai.exe").VersionInfo
  $manifest = Get-Content pubspec.yaml -Raw
  if ($manifest -notmatch '(?m)^version: (\d+)\.(\d+)\.(\d+)\+(\d+)\r?$') { throw 'Invalid pubspec version.' }
  $expected = "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
  $actual = "$($version.FileMajorPart).$($version.FileMinorPart).$($version.FileBuildPart).$($version.FilePrivatePart)"
  if ($actual -ne $expected) { throw "Native version $actual != $expected" }
  Start-Process -FilePath "$app/nexus_ai.exe" | Out-Null
  Close-App (Wait-App)
  Assert-State
  Invoke-Setup 'reinstall-and-relaunch' @('/RELAUNCH=1')
  Close-App (Wait-App)
  Assert-State
  if (@(Get-ChildItem $app -Filter 'unins*.exe').Count -ne 1) { throw 'Duplicate uninstallers.' }
  $uninstaller = Start-Process -FilePath "$app/unins000.exe" -ArgumentList @(
    '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$log/uninstall.txt`"") -PassThru
  if (-not $uninstaller.WaitForExit(120000)) { throw 'Uninstall timed out.' }
  if ($uninstaller.ExitCode -ne 0) { throw "Uninstall exit code $($uninstaller.ExitCode)" }
  if ((Test-Path "$app/nexus_ai.exe") -or (Test-Path $registry) -or
      (Test-Path $start) -or (Test-Path $desktop)) { throw 'Uninstall left application/registration/shortcuts.' }
  Assert-State
  'PASS: per-user path/HKCU, shortcuts, native version/window/close, reinstall/relaunch, uninstall, external state preserved.' |
    Tee-Object "$log/installer-smoke.txt"
  'LIMIT: hosted runner account may be elevated. No standard-user/UAC or in-app editing/real two-version upgrade proof.' |
    Tee-Object -Append "$log/installer-smoke.txt"
} catch {
  $message = $_.Exception.Message.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
  Write-Output "::error::$message"
  throw
} finally {
  # Never hide failure with a cleanup success. The hosted VM is discarded later.
  Get-Process nexus_ai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Continue
}
