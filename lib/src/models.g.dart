// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  return Event(
    calenderId: json['calenderId'] as String,
    title: json['title'] as String,
    startDate: const DateJsonConverter().fromJson(json['startDate'] as int),
    endDate: const DateJsonConverter().fromJson(json['endDate'] as int),
    description: json['description'] as String,
    location: json['location'] as String,
  );
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'calenderId': instance.calenderId,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'startDate': const DateJsonConverter().toJson(instance.startDate),
      'endDate': const DateJsonConverter().toJson(instance.endDate),
    };

Calendar _$CalendarFromJson(Map<String, dynamic> json) {
  return Calendar(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$CalendarToJson(Calendar instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
