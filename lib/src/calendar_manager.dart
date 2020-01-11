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
    await _invokeMethod('createCalender', calendar);
  }

  Future<T> _invokeMethod<T>(String method, dynamic args) {
    return _channel.invokeMethod(method, jsonEncode(args));
  }

  Future<void> deleteAllEventsByCalendarId(String calendarId) async {
    assert(calendarId != null);
    await _invokeMethod("deleteAllEventsByCalendarId", calendarId);
  }

  Future<void> createEvents(Iterable<Event> events) async {
    assert(events != null);
    assert(events.isNotEmpty);
    await _invokeMethod("createEvents", events);
  }
}
