// api_config.dart
class ApiConfig {
  /// 🧩 Địa chỉ server chính (chỉnh thủ công tại đây khi cần)
  static const String baseUrl = 'http://10.12.50.59:5000/';
  static String get activeBaseUrl =>
      baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  static String get activeBaseUrlSafe => activeBaseUrl;
}
