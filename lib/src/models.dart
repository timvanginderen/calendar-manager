import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'converters/date_json_converter.dart';

part 'models.g.dart';

@JsonSerializable()
@DateJsonConverter()
class Event {
  final String calendarId, title, description, location;
  final DateTime startDate, endDate;

  const Event({
    @required this.calendarId,
    @required this.title,
    @required this.startDate,
    @required this.endDate,
    this.description,
    this.location,
  })  : assert(calendarId != null),
        assert(title != null),
        assert(startDate != null),
        assert(endDate != null);

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          calendarId == other.calendarId &&
          title == other.title &&
          description == other.description &&
          location == other.location &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      calendarId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      location.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() {
    return 'Event{calenderId: $calendarId, title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate}';
  }
}

@JsonSerializable()
class Calendar {
  final String id, name;

  const Calendar({@required this.id, @required this.name})
      : assert(id != null),
        assert(name != null);

  @override
  String toString() {
    return 'Calendar{id: $id, name: $name}';
  }

  factory Calendar.fromJson(Map<String, dynamic> json) =>
      _$CalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Calendar &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
