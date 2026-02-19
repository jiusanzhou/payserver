import 'package:flutter/services.dart';

/// Service to handle battery optimization settings
class BatteryService {
  static const _channel = MethodChannel('im.zoe.side.payagent/battery');

  /// Check if battery optimization is ignored for this app
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request to ignore battery optimizations
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open battery optimization settings
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      // Ignore
    }
  }
}
