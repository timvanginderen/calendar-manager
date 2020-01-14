import 'package:calendar_manager/calendar_manager.dart';
import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {}

abstract class MainViewModel implements ViewModel {
  bool get isLoading;

  Future<void> onAddEventClick();

  factory MainViewModel() => MainViewModelImpl(CalendarManager());
}

const TEST_CALENDAR_ID = '125789654323578';

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

  Future<void> createEvents() async {
    const calendarId = TEST_CALENDAR_ID;
    final createCalendar = const CreateCalendar(
        name: "Calendar Example",
        androidInfo: const CreateCalendarAndroidInfo(id: calendarId));

    final calendars = await calendarManager.findAllCalendars();
    print('calendars: $calendars');
    var calendar = calendars.firstWhere((c) => c.name == createCalendar.name,
        orElse: () => null);
    if (calendar != null) {
      await calendarManager.deleteCalendar(calendar.id);
    }
    calendar = await calendarManager.createCalendar(createCalendar);

    final event = Event(
      calendarId: calendar.id,
      title: "Event 1",
      startDate: DateTime.now().add(Duration(hours: 1)),
      endDate: DateTime.now().add(Duration(hours: 2)),
      location: "New York",
      description: "Description 1",
    );
    await calendarManager.createEvent(event);
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    await createEvents();
    isLoading = false;
    notifyListeners();
  }
}
