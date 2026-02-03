import 'package:json_annotation/json_annotation.dart';

part 'ocr_response.g.dart';

@JsonSerializable()
class OcrResponse {
  const OcrResponse({
    required this.count,
    this.date,
  });

  final int count;
  final OcrDateInfo? date;

  /// 是否有辨識到有效日期
  bool get hasValidDate => count > 0 && date != null;

  factory OcrResponse.fromJson(Map<String, dynamic> json) =>
      _$OcrResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OcrResponseToJson(this);
}

@JsonSerializable()
class OcrDateInfo {
  const OcrDateInfo({
    this.production,
    this.expiration,
  });

  final OcrDate? production;
  final OcrDate? expiration;

  factory OcrDateInfo.fromJson(Map<String, dynamic> json) =>
      _$OcrDateInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OcrDateInfoToJson(this);
}

@JsonSerializable()
class OcrDate {
  const OcrDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  factory OcrDate.fromJson(Map<String, dynamic> json) =>
      _$OcrDateFromJson(json);

  Map<String, dynamic> toJson() => _$OcrDateToJson(this);

  /// 轉換為 DateTime
  DateTime toDateTime() => DateTime(year, month, day);

  @override
  String toString() => '$year/$month/$day';
}
