import 'package:calendar_manager/calendar_manager.dart';
import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {}

abstract class MainViewModel implements ViewModel {
  bool get isLoading;

  Future<void> onCreateEventClick();
  Future<void> onDeleteCalendarClick();
  Future<void> onCreateCalendarClick();
  Future<void> onCauseCrashClick();

  factory MainViewModel() => MainViewModelImpl(CalendarManager());
}

const TEST_CALENDAR_ID = '1257896543';
const TEST_CALENDAR_NAME = 'DummyCalendar';
const int TEST_COLOR = 0x056b9c;

class MainViewModelImpl extends ViewModel implements MainViewModel {
  @override
  bool isLoading = false;

  final CalendarManager calendarManager;

  MainViewModelImpl(this.calendarManager);

  Future<void> doCall<T>(Future<T> call()) async {
    if (isLoading) {
      print('already loading please wait!');
      return;
    }
    isLoading = true;
    notifyListeners();
    try {
      return await call();
    } catch (ex, s) {
      print('crash catch:');
      print(ex);
      print(s);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  @override
  Future<void> onCreateCalendarClick() => doCall(() async {
        final createCalendar = const CreateCalendar(
            name: TEST_CALENDAR_NAME,
            color: TEST_COLOR,
            androidInfo: const CreateCalendarAndroidInfo(id: TEST_CALENDAR_ID));
        final CalendarResult calendarResult =
            await calendarManager.createCalendar(createCalendar);
        print(
            "cal result color: ${calendarResult.color} , test color: $TEST_COLOR");
        assert(calendarResult.color == TEST_COLOR);
      });

  @override
  Future<void> onCreateEventClick() => doCall(() async {
        final calendar = await findCalendar();
        final event = Event(
          calendarId: calendar.id,
          title: "Calendar plugin works!",
          startDate: DateTime.now().add(Duration(hours: 1)),
          endDate: DateTime.now().add(Duration(hours: 2)),
          location: "Edegem",
          description:
              "The calendar manager plugin has successfully created an event to the created calendar.",
        );
        await calendarManager.createEvent(event);
      });

  Future<CalendarResult> findCalendar() async {
    final List<CalendarResult> calendars =
        await calendarManager.findAllCalendars();
    final calendar = calendars.firstOrNull(
        (cal) => cal.id == TEST_CALENDAR_ID || cal.name == TEST_CALENDAR_NAME);
    return calendar;
  }

  @override
  Future<void> onDeleteCalendarClick() => doCall(() async {
        final calendar = await findCalendar();
        if (calendar != null)
          await calendarManager.deleteCalendar(calendar.id);
        else
          print('calendar not found');
      });

  @override
  Future<void> onCauseCrashClick() async {
    // see if exception is thrown
    calendarManager.deleteCalendar("not existing id");
  }
}

extension<T> on Iterable<T> {
  T firstOrNull(bool test(T element)) {
    return this.firstWhere(test, orElse: () => null);
  }
}
