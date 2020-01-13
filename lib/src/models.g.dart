// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  return Event(
    title: json['title'] as String,
    startDate: const DateJsonConverter().fromJson(json['startDate'] as int),
    endDate: const DateJsonConverter().fromJson(json['endDate'] as int),
    description: json['description'] as String,
    location: json['location'] as String,
  );
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'startDate': const DateJsonConverter().toJson(instance.startDate),
      'endDate': const DateJsonConverter().toJson(instance.endDate),
    };

Calendar _$CalendarFromJson(Map<String, dynamic> json) {
  return Calendar(
    name: json['name'],
  );
}

Map<String, dynamic> _$CalendarToJson(Calendar instance) => <String, dynamic>{
      'name': instance.name,
    };
