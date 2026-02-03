// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OcrResponse _$OcrResponseFromJson(Map<String, dynamic> json) => OcrResponse(
  count: (json['count'] as num).toInt(),
  date: json['date'] == null
      ? null
      : OcrDateInfo.fromJson(json['date'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OcrResponseToJson(OcrResponse instance) =>
    <String, dynamic>{'count': instance.count, 'date': instance.date};

OcrDateInfo _$OcrDateInfoFromJson(Map<String, dynamic> json) => OcrDateInfo(
  production: json['production'] == null
      ? null
      : OcrDate.fromJson(json['production'] as Map<String, dynamic>),
  expiration: json['expiration'] == null
      ? null
      : OcrDate.fromJson(json['expiration'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OcrDateInfoToJson(OcrDateInfo instance) =>
    <String, dynamic>{
      'production': instance.production,
      'expiration': instance.expiration,
    };

OcrDate _$OcrDateFromJson(Map<String, dynamic> json) => OcrDate(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  day: (json['day'] as num).toInt(),
);

Map<String, dynamic> _$OcrDateToJson(OcrDate instance) => <String, dynamic>{
  'year': instance.year,
  'month': instance.month,
  'day': instance.day,
};
