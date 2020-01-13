import 'package:calendar_manager/calendar_manager.dart';
import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {}

abstract class MainViewModel implements ViewModel {
  bool get isLoading;

  Future<void> onAddEventClick();

  factory MainViewModel() => MainViewModelImpl(CalendarManager());
}

const TEST_CALENDAR_ID = '123543';

class MainViewModelImpl extends ViewModel implements MainViewModel {
  @override
  bool isLoading = false;

  final CalendarManager calendarManager;

  MainViewModelImpl(this.calendarManager);

  @override
  Future<void> onAddEventClick() async {
    try {
      await load();
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final calendar = const Calendar(name: "Calendar Example");

    final event = Event(
      title: "Event 1",
      startDate: DateTime.now().add(Duration(hours: 1)),
      endDate: DateTime.now().add(Duration(hours: 2)),
      location: "New York",
      description: "Description 1",
    );
    await calendarManager.createCalendar(calendar);
    await calendarManager.deleteAllEventsByCalendar(calendar);
    await calendarManager.createEvents(calendar, [event]);
    isLoading = false;
    notifyListeners();
  }
}
