import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_manager/calendar_manager.dart';

extension DateTimeExtensions on DateTime {
  DateTime truncateMicroseconds() => DateTime(this.year, this.month, this.day,
      this.hour, this.minute, this.second, this.millisecond);
}

void main() {
  const MethodChannel channel = MethodChannel('rmdy.be/calendar_manager');
  CalendarManager calendarManager;
  Completer<String> paramCapture;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      calendarManager = CalendarManager();
      final name = methodCall.method;
      final args = methodCall.arguments;
      print('$name: $args');
      paramCapture.complete(methodCall.arguments);
      return '42';
    });
    paramCapture = Completer();
    calendarManager = CalendarManager();
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('CalendarManager', () {
    test('createCalendar', () async {
      final calendar = Calendar(id: "123", name: "Calendar 1");
      await calendarManager.createCalendar(calendar);
      final param = await paramCapture.future;
      expect(Calendar.fromJson(jsonDecode(param)), calendar);
    });

    test('createEvents', () async {
      final calendar = Calendar(id: "123", name: "Calendar 1");
      final event = Event(
        title: "Event 1",
        startDate:
            DateTime.now().truncateMicroseconds().add(Duration(hours: 1)),
        endDate: DateTime.now().truncateMicroseconds().add(Duration(hours: 2)),
        calendarId: calendar.id,
        location: "New York",
        description: "Description 1",
      );
      final events = [event];
      await calendarManager.createEvents(events);
      final param = await paramCapture.future;
      Iterable l = json.decode(param);
      final decodedEvents = l.map((x) => Event.fromJson(x)).toList();
      expect(decodedEvents, events);
    });

    test('deleteAllEventsByCalendarId', () async {
      final calendarId = "123";
      await calendarManager.deleteAllEventsByCalendarId(calendarId);
      final param = await paramCapture.future;
      final decodedCalendarId = jsonDecode(param);
      expect(decodedCalendarId, calendarId);
    });
  });
}
