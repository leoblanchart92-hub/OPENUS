#ifndef MyAppVersion
  #error MyAppVersion must come from pubspec.yaml
#endif

[Setup]
AppId={{A42A3B2D-7E91-4B61-9D1A-7C2B7A9F0D31}
AppName=Nexus AI
AppVersion={#MyAppVersion}
AppPublisher=Nexus AI
AppPublisherURL=https://github.com/leoblanchart92-hub/OPENUS
DefaultDirName={localappdata}\Programs\Nexus AI
DefaultGroupName=Nexus AI
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\..\artifacts
OutputBaseFilename=Nexus-AI-Setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayName=Nexus AI
UninstallDisplayIcon={app}\nexus_ai.exe
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
SetupMutex=NexusAISetup
CloseApplicationsFilter=nexus_ai.exe
MinVersion=10.0

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"; Flags: unchecked

[Files]
Source: "..\..\distribution\Nexus-AI-Windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Nexus AI"; Filename: "{app}\nexus_ai.exe"
Name: "{autodesktop}\Nexus AI"; Filename: "{app}\nexus_ai.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\nexus_ai.exe"; Description: "Lancer Nexus AI"; Flags: nowait postinstall; Check: ShouldRelaunch

[Code]
function ShouldRelaunch: Boolean;
begin
  Result := (not WizardSilent) or (ExpandConstant('{param:RELAUNCH|0}') = '1');
end;
