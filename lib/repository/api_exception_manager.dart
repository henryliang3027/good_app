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
