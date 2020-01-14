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
  Completer<Map<String, dynamic>> paramCapture;

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
      final calendar = CreateCalendar(name: "Calendar 1");
      await calendarManager.createCalendar(calendar);
      final param = await paramCapture.future;
      expect(CreateCalendar.fromJson(jsonDecode(param["calendar"])), calendar);
    });

    test('createEvents', () async {
      final calendar = CreateCalendar(name: "Calendar 1");
      final event = Event(
        title: "Event 1",
        calendarId: "23",
        startDate:
            DateTime.now().truncateMicroseconds().add(Duration(hours: 1)),
        endDate: DateTime.now().truncateMicroseconds().add(Duration(hours: 2)),
        location: "New York",
        description: "Description 1",
      );
      final events = [event];
      await calendarManager.createEvents(events);
      final param = await paramCapture.future;
      Iterable l = json.decode(param['events']);
      final decodedCalendar = json.decode(param['calendar']);
      final decodedEvents = l.map((x) => Event.fromJson(x)).toList();
      expect(decodedEvents, events);
      expect(decodedCalendar, calendar);
    });

    test('deleteAllEventsByCalendarId', () async {
      final calendar = CreateCalendar(name: "Calendar 1");
      await calendarManager.deleteCalendar("123");
      final param = await paramCapture.future;
      final decodedCalendar = jsonDecode(param["calendarId"]);
      expect(decodedCalendar, calendar);
    });
  });
}
