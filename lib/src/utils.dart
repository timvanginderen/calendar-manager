import 'package:calendar_manager/calendar_manager.dart';

CalendarManagerErrorCode parseCalendarManagerErrorCode(String code) {
  if (code == null) throw ArgumentError.notNull(code);
  return CalendarManagerErrorCode.values.firstWhere((x) => x.name == code,
      orElse: () => throw Exception('error code not recognized: $code'));
}
