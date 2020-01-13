import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'converters/date_json_converter.dart';

part 'models.g.dart';

@JsonSerializable()
@DateJsonConverter()
class Event extends Equatable {
  final String title, description, location;
  final DateTime startDate, endDate;

  const Event({
    @required this.title,
    @required this.startDate,
    @required this.endDate,
    this.description,
    this.location,
  })  : assert(title != null),
        assert(startDate != null),
        assert(endDate != null);

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  @override
  String toString() {
    return 'Event{title: $title, description: $description, location: $location, startDate: $startDate, endDate: $endDate}';
  }

  @override
  List<Object> get props => [title, description, location, startDate, endDate];
}

@JsonSerializable()
class Calendar extends Equatable {
  final name;

  const Calendar({@required this.name}) : assert(name != null);

  @override
  String toString() {
    return 'Calendar{name: $name}';
  }

  @override
  List<Object> get props => [name];

  factory Calendar.fromJson(Map<String, dynamic> json) =>
      _$CalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);
}
