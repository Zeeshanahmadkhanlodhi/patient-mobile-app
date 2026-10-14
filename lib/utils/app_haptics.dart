import 'package:flutter/services.dart';

/// Shared CarePath haptic cues.
class AppHaptics {
  AppHaptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> action() => HapticFeedback.lightImpact();

  static Future<void> success() => HapticFeedback.mediumImpact();
}
