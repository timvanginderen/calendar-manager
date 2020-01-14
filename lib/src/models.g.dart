// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const [
    'calendarId',
    'title',
    'description',
    'location',
    'startDate',
    'endDate'
  ]);
  return Event(
    calendarId: json['calendarId'] as String,
    title: json['title'] as String,
    startDate: const DateJsonConverter().fromJson(json['startDate'] as int),
    endDate: const DateJsonConverter().fromJson(json['endDate'] as int),
    description: json['description'] as String,
    location: json['location'] as String,
  );
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'calendarId': instance.calendarId,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'startDate': const DateJsonConverter().toJson(instance.startDate),
      'endDate': const DateJsonConverter().toJson(instance.endDate),
    };

CalendarResult _$CalendarResultFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['id', 'name', 'color', 'isReadOnly']);
  return CalendarResult(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as int,
    isReadOnly: json['isReadOnly'] as bool,
  );
}

Map<String, dynamic> _$CalendarResultToJson(CalendarResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'isReadOnly': instance.isReadOnly,
    };

CreateCalendar _$CreateCalendarFromJson(Map<String, dynamic> json) {
  return CreateCalendar(
    name: json['name'] as String,
    color: json['color'] as int,
    androidInfo: json['androidInfo'] == null
        ? null
        : CreateCalendarAndroidInfo.fromJson(
            json['androidInfo'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateCalendarToJson(CreateCalendar instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'androidInfo': instance.androidInfo,
    };

CreateCalendarAndroidInfo _$CreateCalendarAndroidInfoFromJson(
    Map<String, dynamic> json) {
  return CreateCalendarAndroidInfo(
    id: json['id'] as String,
  );
}

Map<String, dynamic> _$CreateCalendarAndroidInfoToJson(
        CreateCalendarAndroidInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
    };
