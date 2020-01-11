import 'package:calendar_manager/calendar_manager.dart';

abstract class CalendarService {
  Future<String> fetchVersion();

  factory CalendarService() => CalendarServiceImpl();
}

class CalendarServiceImpl implements CalendarService {
  @override
  fetchVersion() {
    return CalendarManager.platformVersion;
  }
}
