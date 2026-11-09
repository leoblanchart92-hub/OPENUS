#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"

namespace {

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

#ifndef DWMWCP_DEFAULT
#define DWMWCP_DEFAULT 0
#endif

#ifndef DWMWCP_ROUND
#define DWMWCP_ROUND 2
#endif

constexpr const char kDesktopWindowChannel[] = "nexus_ai/desktop_window";

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetupDesktopWindowChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  desktop_window_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::SetupDesktopWindowChannel() {
  desktop_window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kDesktopWindowChannel,
          &flutter::StandardMethodCodec::GetInstance());

  desktop_window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const std::string& method = call.method_name();

        if (method == "getCapabilities") {
          flutter::EncodableMap capabilities;
          capabilities[flutter::EncodableValue("supported")] =
              flutter::EncodableValue(true);
          capabilities[flutter::EncodableValue("compactMode")] =
              flutter::EncodableValue(true);
          capabilities[flutter::EncodableValue("alwaysOnTop")] =
              flutter::EncodableValue(true);
          capabilities[flutter::EncodableValue("minimize")] =
              flutter::EncodableValue(true);
          capabilities[flutter::EncodableValue("dragWindow")] =
              flutter::EncodableValue(true);
          capabilities[flutter::EncodableValue("isCompact")] =
              flutter::EncodableValue(is_compact_mode_);
          capabilities[flutter::EncodableValue("isAlwaysOnTop")] =
              flutter::EncodableValue(is_always_on_top_);
          result->Success(flutter::EncodableValue(capabilities));
          return;
        }

        if (method == "setCompactMode") {
          bool compact = false;
          int width = 300;
          int height = 380;

          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto compact_it = args->find(flutter::EncodableValue("compact"));
            if (compact_it != args->end()) {
              if (const auto* val = std::get_if<bool>(&compact_it->second)) {
                compact = *val;
              }
            }
            auto width_it = args->find(flutter::EncodableValue("width"));
            if (width_it != args->end()) {
              if (auto val = width_it->second.TryGetLongValue()) {
                width = static_cast<int>(std::clamp<std::int64_t>(*val, 240, 1600));
              }
            }
            auto height_it = args->find(flutter::EncodableValue("height"));
            if (height_it != args->end()) {
              if (auto val = height_it->second.TryGetLongValue()) {
                height = static_cast<int>(std::clamp<std::int64_t>(*val, 280, 1600));
              }
            }
          }

          if (!ApplyCompactMode(compact, width, height)) {
            result->Error("window_operation_failed", "Unable to change compact mode.");
            return;
          }
          result->Success(flutter::EncodableValue(is_compact_mode_));
          return;
        }

        if (method == "setAlwaysOnTop") {
          bool always_on_top = false;
          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto it = args->find(flutter::EncodableValue("alwaysOnTop"));
            if (it != args->end()) {
              if (const auto* val = std::get_if<bool>(&it->second)) {
                always_on_top = *val;
              }
            }
          }

          if (!ApplyAlwaysOnTop(always_on_top)) {
            result->Error("window_operation_failed", "Unable to change always-on-top.");
            return;
          }
          result->Success(flutter::EncodableValue(is_always_on_top_));
          return;
        }

        if (method == "minimizeWindow") {
          result->Success(flutter::EncodableValue(MinimizeWindow()));
          return;
        }

        if (method == "restoreWindow") {
          result->Success(flutter::EncodableValue(RestoreWindow()));
          return;
        }

        if (method == "startWindowDrag") {
          result->Success(flutter::EncodableValue(StartWindowDrag()));
          return;
        }

        result->NotImplemented();
      });
}

bool FlutterWindow::ApplyCompactMode(bool compact, int width, int height) {
  HWND hwnd = GetHandle();
  if (!hwnd) {
    return false;
  }
  if (compact == is_compact_mode_) {
    return true;
  }

  // Keep a rollback snapshot: never acknowledge a failed transition to Dart.
  WINDOWPLACEMENT previous_placement{};
  previous_placement.length = sizeof(WINDOWPLACEMENT);
  if (!::GetWindowPlacement(hwnd, &previous_placement)) {
    return false;
  }
  const LONG_PTR previous_style = ::GetWindowLongPtr(hwnd, GWL_STYLE);
  const auto set_style = [hwnd](LONG_PTR style) {
    ::SetLastError(ERROR_SUCCESS);
    const LONG_PTR previous = ::SetWindowLongPtr(hwnd, GWL_STYLE, style);
    return previous != 0 || ::GetLastError() == ERROR_SUCCESS;
  };
  const auto rollback = [&]() {
    set_style(previous_style);
    ::SetWindowPlacement(hwnd, &previous_placement);
    ::SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  };

  if (compact) {
    saved_window_placement_ = previous_placement;
    // Do not restore a minimized state when leaving the compact view.
    if (saved_window_placement_.showCmd == SW_SHOWMINIMIZED) {
      saved_window_placement_.showCmd = SW_SHOWNORMAL;
    }
    if (::IsZoomed(hwnd) || ::IsIconic(hwnd)) {
      ::ShowWindow(hwnd, SW_RESTORE);
    }

    saved_window_style_ = ::GetWindowLongPtr(hwnd, GWL_STYLE);
    if (!::GetWindowRect(hwnd, &saved_window_rect_)) {
      rollback();
      return false;
    }

    HMONITOR monitor = ::MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
    double scale = static_cast<double>(dpi) / 96.0;
    int scaled_w = std::max(240, static_cast<int>(width * scale));
    int scaled_h = std::max(280, static_cast<int>(height * scale));

    MONITORINFO monitor_info{};
    monitor_info.cbSize = sizeof(MONITORINFO);
    int target_x = 40;
    int target_y = 40;
    if (::GetMonitorInfo(monitor, &monitor_info)) {
      const RECT& work = monitor_info.rcWork;
      int margin = static_cast<int>(24 * scale);
      target_x = std::max(static_cast<int>(work.left),
                          static_cast<int>(work.right) - scaled_w - margin);
      target_y = std::max(static_cast<int>(work.top),
                          static_cast<int>(work.bottom) - scaled_h - margin);
    }

    if (!set_style(WS_POPUP | WS_CLIPCHILDREN | WS_VISIBLE)) {
      rollback();
      return false;
    }

    DWORD corner_pref = DWMWCP_ROUND;
    ::DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                            &corner_pref, sizeof(corner_pref));

    HWND z_order = is_always_on_top_ ? HWND_TOPMOST : HWND_NOTOPMOST;
    if (!::SetWindowPos(hwnd, z_order, target_x, target_y, scaled_w, scaled_h,
                        SWP_FRAMECHANGED | SWP_SHOWWINDOW)) {
      rollback();
      return false;
    }
    has_saved_window_state_ = true;
    is_compact_mode_ = true;
  } else {
    LONG_PTR restore_style = has_saved_window_state_
                                 ? saved_window_style_
                                 : (WS_OVERLAPPEDWINDOW | WS_VISIBLE);
    if (!set_style(restore_style)) {
      return false;
    }

    DWORD corner_pref = DWMWCP_DEFAULT;
    ::DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                            &corner_pref, sizeof(corner_pref));

    int x = has_saved_window_state_ ? static_cast<int>(saved_window_rect_.left)
                                    : 60;
    int y = has_saved_window_state_ ? static_cast<int>(saved_window_rect_.top)
                                    : 40;
    int w = has_saved_window_state_
                ? static_cast<int>(saved_window_rect_.right -
                                   saved_window_rect_.left)
                : 1280;
    int h = has_saved_window_state_
                ? static_cast<int>(saved_window_rect_.bottom -
                                   saved_window_rect_.top)
                : 800;

    HWND z_order = is_always_on_top_ ? HWND_TOPMOST : HWND_NOTOPMOST;
    if (!::SetWindowPos(hwnd, z_order, x, y, w, h,
                        SWP_FRAMECHANGED | SWP_SHOWWINDOW) ||
        (has_saved_window_state_ &&
         !::SetWindowPlacement(hwnd, &saved_window_placement_))) {
      rollback();
      return false;
    }
    is_compact_mode_ = false;
  }
  return true;
}

bool FlutterWindow::ApplyAlwaysOnTop(bool always_on_top) {
  HWND hwnd = GetHandle();
  if (!hwnd || !::SetWindowPos(
                   hwnd, always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST,
                   0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)) {
    return false;
  }
  is_always_on_top_ = always_on_top;
  return true;
}

bool FlutterWindow::MinimizeWindow() {
  HWND hwnd = GetHandle();
  if (!hwnd || !::IsWindow(hwnd)) {
    return false;
  }
  ::ShowWindow(hwnd, SW_MINIMIZE);
  return ::IsIconic(hwnd) != FALSE;
}

bool FlutterWindow::RestoreWindow() {
  HWND hwnd = GetHandle();
  if (!hwnd || !::IsWindow(hwnd)) {
    return false;
  }
  ::ShowWindow(hwnd, SW_RESTORE);
  ::SetForegroundWindow(hwnd);  // Foreground focus is subject to Windows policy.
  return ::IsWindowVisible(hwnd) && !::IsIconic(hwnd);
}

bool FlutterWindow::StartWindowDrag() {
  HWND hwnd = GetHandle();
  POINT cursor{};
  if (!hwnd || !::IsWindow(hwnd) || !::GetCursorPos(&cursor)) {
    return false;
  }
  ::ReleaseCapture();
  ::SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION,
                MAKELPARAM(cursor.x, cursor.y));
  // This confirms drag dispatch, not that the user actually moved the window.
  return true;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_ && flutter_controller_->engine()) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
