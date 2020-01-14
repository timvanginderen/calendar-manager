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
  $checkKeys(json, allowedKeys: const ['id', 'name', 'isReadOnly']);
  return CalendarResult(
    id: json['id'] as String,
    name: json['name'] as String,
    isReadOnly: json['isReadOnly'] as bool,
  );
}

Map<String, dynamic> _$CalendarResultToJson(CalendarResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isReadOnly': instance.isReadOnly,
    };

CreateCalendar _$CreateCalendarFromJson(Map<String, dynamic> json) {
  return CreateCalendar(
    name: json['name'],
    androidInfo: json['androidInfo'],
  );
}

Map<String, dynamic> _$CreateCalendarToJson(CreateCalendar instance) =>
    <String, dynamic>{
      'name': instance.name,
      'androidInfo': instance.androidInfo,
    };

CreateCalendarAndroidInfo _$CreateCalendarAndroidInfoFromJson(
    Map<String, dynamic> json) {
  return CreateCalendarAndroidInfo(
    id: json['id'],
  );
}

Map<String, dynamic> _$CreateCalendarAndroidInfoToJson(
        CreateCalendarAndroidInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
    };
