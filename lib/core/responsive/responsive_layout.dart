import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive screen tiers covering compact desktop companion windows,
/// mobile phones, tablets, and full desktop viewports.
enum NexusScreenClass {
  compactWindow,
  mobile,
  tablet,
  desktop,
}

abstract final class ResponsiveLayout {
  static const double compactMaxWidth = 410;
  static const double mobileMaxWidth = 720;
  static const double tabletMaxWidth = 1080;

  static NexusScreenClass classifyWidth(double width) {
    if (width <= compactMaxWidth) {
      return NexusScreenClass.compactWindow;
    }
    if (width <= mobileMaxWidth) {
      return NexusScreenClass.mobile;
    }
    if (width <= tabletMaxWidth) {
      return NexusScreenClass.tablet;
    }
    return NexusScreenClass.desktop;
  }

  static NexusScreenClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return classifyWidth(width);
  }

  static bool usesSidebarNavigation(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMaxWidth;
  }

  static bool isDesktopOrWeb() {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool isWindowsPlatform() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }
}
