#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that hosts the Nexus AI Flutter view and provides native Windows
// companion window management (compact floating mode, always-on-top,
// minimize/restore, and drag support) via a Flutter MethodChannel.
class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupDesktopWindowChannel();
  bool ApplyCompactMode(bool compact, int width, int height);
  bool ApplyAlwaysOnTop(bool always_on_top);
  bool MinimizeWindow();
  bool RestoreWindow();
  bool StartWindowDrag();

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      desktop_window_channel_;

  bool is_compact_mode_ = false;
  bool is_always_on_top_ = false;
  LONG_PTR saved_window_style_ = 0;
  RECT saved_window_rect_{0, 0, 1280, 800};
  bool has_saved_window_state_ = false;
  WINDOWPLACEMENT saved_window_placement_{};
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
