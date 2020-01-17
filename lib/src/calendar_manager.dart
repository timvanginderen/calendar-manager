import 'dart:async';
import 'dart:convert';

import 'package:calendar_manager/src/utils.dart';
import 'package:flutter/services.dart';

import '../calendar_manager.dart';

export 'package:calendar_manager/src/models.dart';

abstract class CalendarManager {
  Future<CalendarResult> createCalendar(CreateCalendar calendar);
  Future<void> deleteCalendar(String calendarId);
  Future<List<CalendarResult>> findAllCalendars();
  Future<void> createEvent(Event event);
  Future<void> createEvents(Iterable<Event> events);
  Future<bool> requestPermissions();
  factory CalendarManager() => CalendarManagerImpl();
}

class CalendarManagerImpl implements CalendarManager {
  static const MethodChannel _channel =
      const MethodChannel('rmdy.be/calendar_manager');

  static final CalendarManager _instance = CalendarManagerImpl._();

  CalendarManagerImpl._();

  factory CalendarManagerImpl() => _instance;

  ///returns the calendarId
  Future<CalendarResult> createCalendar(CreateCalendar calendar) async {
    assert(calendar != null);
    await requestPermissionsOrThrow();
    final String json = await _invokeMethod(
        'createCalendar', {"calendar": jsonEncode(calendar)});
    return CalendarResult.fromJson(jsonDecode(json));
  }

  Future<T> _invokeMethod<T>(String method, Map<String, dynamic> args) async {
    try {
      final result = await _channel.invokeMethod(method, args);
      return result;
    } on PlatformException catch (ex) {
      throw CalendarManagerException(
          code: parseCalendarManagerErrorCode(ex.code),
          details: ex.details,
          message: ex.message);
    }
  }

  Future<void> deleteCalendar(String calendarId) async {
    assert(calendarId != null);
    await requestPermissionsOrThrow();
    return await _invokeMethod("deleteCalendar", {"calendarId": calendarId});
  }

  Future<List<CalendarResult>> findAllCalendars() async {
    await requestPermissionsOrThrow();
    final String json = await _invokeMethod("findAllCalendars", {});
    Iterable results = jsonDecode(json);
    return results.map((c) => CalendarResult.fromJson(c)).toList();
  }

  Future<void> requestPermissionsOrThrow() async {
    bool granted = await requestPermissions();
    if (!granted) {
      throw CalendarManagerException(
          code: CalendarManagerErrorCode.PERMISSIONS_NOT_GRANTED);
    }
  }

  Future<bool> requestPermissions() async {
    bool granted = await _invokeMethod("requestPermissions", {});
    return granted;
  }

  Future<void> createEvent(Event event) async {
    assert(event != null);
    await requestPermissionsOrThrow();
    return _createEvent(event);
  }

  Future<void> _createEvent(Event event) async {
    await _invokeMethod("createEvent", {"event": jsonEncode(event)});
  }

  Future<void> createEvents(Iterable<Event> events) async {
    assert(events != null);
    assert(events.isNotEmpty);
    assert(events.every((event) => event != null));
    await requestPermissionsOrThrow();
    for (final event in events) {
      await _createEvent(event);
    }
  }
}
