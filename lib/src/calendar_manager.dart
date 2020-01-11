import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../calendar_manager.dart';

export 'package:calendar_manager/src/models.dart';

class CalendarManager {
  static const MethodChannel _channel =
      const MethodChannel('rmdy.be/calendar_manager');

  static final CalendarManager _instance = CalendarManager._();

  CalendarManager._();

  factory CalendarManager() => _instance;

  Future<void> createCalendar(Calendar calendar) async {
    assert(calendar != null);
    await _channel.invokeMethod(
        'createCalender', jsonEncode(calendar.toJson()));
  }

  Future<void> createOrUpdateEvent(Event event) async {
    assert(event != null);
    await _channel.invokeMethod(
        'createOrUpdateEvent', jsonEncode(event.toJson()));
  }
}
