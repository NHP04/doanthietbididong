// api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.2.48:5000/';
  static String get activeBaseUrl =>
      baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  static String get activeBaseUrlSafe => activeBaseUrl;
}
