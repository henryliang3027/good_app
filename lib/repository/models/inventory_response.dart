import 'package:json_annotation/json_annotation.dart';

part 'inventory_response.g.dart';

@JsonSerializable()
class InventoryResponse {
  const InventoryResponse({
    required this.status,
    required this.data,
  });

  final int status;
  final String data;

  /// 是否成功
  bool get isSuccess => status == 1;

  factory InventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryResponseToJson(this);
}
