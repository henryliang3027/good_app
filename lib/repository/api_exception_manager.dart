import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// API 客戶端相關異常
sealed class ApiClientException implements Exception {
  const ApiClientException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 伺服器無法連線異常
class ServerUnavailableException extends ApiClientException {
  const ServerUnavailableException([super.message = '伺服器無法連線，請稍後再試']);
}

/// 請求超時異常
class RequestTimeoutException extends ApiClientException {
  const RequestTimeoutException([super.message = '請求超時，請檢查網路連線']);
}

/// 伺服器錯誤異常
class ServerErrorException extends ApiClientException {
  const ServerErrorException([super.message = '伺服器發生錯誤']);
}

/// 圖片檔案異常
class ImageFileException extends ApiClientException {
  const ImageFileException([super.message = '無法讀取圖片檔案']);
}

/// 將 [DioException] 或 [TimeoutException] 轉換為對應的 [ApiClientException]
ApiClientException handleApiException(Exception e) {
  if (e is TimeoutException) {
    return const RequestTimeoutException();
  }

  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.connectionError:
        return const ServerUnavailableException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return const ServerUnavailableException('後端服務未啟動 (404)');
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerErrorException('伺服器錯誤 ($statusCode)');
        }
        return ServerErrorException('請求失敗 ($statusCode)');

      case DioExceptionType.cancel:
        return const ServerUnavailableException('請求已取消');

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        if (e.error is SocketException) {
          return const ServerUnavailableException();
        }
        return ServerUnavailableException('網路錯誤: ${e.message}');
    }
  }

  return ServerErrorException('未知錯誤: $e');
}
