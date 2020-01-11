import 'package:json_annotation/json_annotation.dart';

class DateJsonConverter implements JsonConverter<DateTime, int> {
  const DateJsonConverter();

  @override
  DateTime fromJson(int json) {
    return DateTime.fromMicrosecondsSinceEpoch(json);
  }

  @override
  int toJson(DateTime object) {
    return object.millisecondsSinceEpoch;
  }
}
