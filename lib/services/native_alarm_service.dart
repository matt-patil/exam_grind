import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.exam_grind/alarm');

  static Future<void> scheduleAlarm(String id, DateTime dateTime, String soundPath, double volume) async {
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': id,
        'timeInMillis': dateTime.millisecondsSinceEpoch,
        'soundPath': soundPath,
        'volume': volume,
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> cancelAlarm(String id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {
        'id': id,
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> muteAlarm() async {
    try {
      await _channel.invokeMethod('muteAlarm');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> unmuteAlarm() async {
    try {
      await _channel.invokeMethod('unmuteAlarm');
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getInitialAlarm() async {
    try {
      return await _channel.invokeMethod<String>('getInitialAlarm');
    } catch (e) {
      // Gracefully handle if Android side not ready
      return null;
    }
  }

  static void setAlarmHandler(Function(String) onAlarmRinging) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmRinging') {
        onAlarmRinging(call.arguments as String);
      }
    });
  }
}
