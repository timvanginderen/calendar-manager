import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'converters/date_json_converter.dart';

part 'models.g.dart';

abstract class _Base extends Equatable {
  const _Base();
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(disallowUnrecognizedKeys: true)
@DateJsonConverter()
class Event extends _Base {
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
  List<Object> get props => [title, description, location, startDate, endDate];
}

@JsonSerializable(disallowUnrecognizedKeys: true)
class CalendarResult extends _Base {
  final String id;
  final String name;
  final int color;
  final bool isReadOnly;

  const CalendarResult({this.id, this.name, this.color, this.isReadOnly});

  @override
  List<Object> get props => [id, name, color, isReadOnly];

  factory CalendarResult.fromJson(Map<String, dynamic> json) =>
      _$CalendarResultFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarResultToJson(this);
}

@JsonSerializable()
class CreateCalendar extends _Base {
  final String name;
  final int color;
  final CreateCalendarAndroidInfo androidInfo;

  const CreateCalendar({@required this.name, this.color, this.androidInfo})
      : assert(name != null);

  @override
  List<Object> get props => [name, color, androidInfo];

  factory CreateCalendar.fromJson(Map<String, dynamic> json) =>
      _$CreateCalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCalendarToJson(this);
}

@JsonSerializable()
class CreateCalendarAndroidInfo extends _Base {
  final String id;

  const CreateCalendarAndroidInfo({@required this.id}) : assert(id != null);

  @override
  List<Object> get props => [id];

  factory CreateCalendarAndroidInfo.fromJson(Map<String, dynamic> json) =>
      _$CreateCalendarAndroidInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCalendarAndroidInfoToJson(this);
}
