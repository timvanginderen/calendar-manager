import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'converters/date_json_converter.dart';

part 'models.g.dart';

@JsonSerializable()
@DateJsonConverter()
class Event {
  final String calenderId, title, description, location;
  final DateTime startDate, endDate;

  const Event({
    @required this.calenderId,
    @required this.title,
    @required this.startDate,
    @required this.endDate,
    this.description,
    this.location,
  })  : assert(calenderId != null),
        assert(title != null),
        assert(startDate != null),
        assert(endDate != null);

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}

@JsonSerializable()
class Calendar {
  final String id, name;

  const Calendar({@required this.id, @required this.name})
      : assert(id != null),
        assert(name != null);

  factory Calendar.fromJson(Map<String, dynamic> json) =>
      _$CalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);
}
