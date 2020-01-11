import 'package:calendar_manager/calendar_manager.dart';
import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {}

abstract class MainViewModel implements ViewModel {
  bool get isLoading;
  String get version;

  factory MainViewModel() => MainViewModelImpl(CalendarManager());
}

class MainViewModelImpl extends ViewModel implements MainViewModel {
  @override
  String version;
  @override
  bool isLoading;

  static const CALENDAR_ID = '123543';

  final CalendarManager calendarManager;

  MainViewModelImpl(this.calendarManager) {
    load();
  }

  load() async {
    isLoading = true;
    notifyListeners();
    final calendar = const Calendar(id: CALENDAR_ID, name: "Calendar Example");

    final event = Event(
      title: "Event 1",
      startDate: DateTime.now().add(Duration(hours: 1)),
      endDate: DateTime.now().add(Duration(hours: 2)),
      calenderId: calendar.id,
      location: "New York",
      description: "Description 1",
    );
    await calendarManager.createCalendar(calendar);
    await calendarManager.deleteAllEventsByCalendarId(calendar.id);
    await calendarManager.createEvents([event]);
    isLoading = false;
    notifyListeners();
  }
}
