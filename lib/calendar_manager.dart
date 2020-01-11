import 'dart:async';

import 'package:flutter/services.dart';

class CalendarManager {
  static const MethodChannel _channel =
      const MethodChannel('be.rmdy.calendar_manager');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
