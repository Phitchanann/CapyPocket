import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultAndroidEmulatorUrl = 'http://10.0.2.2:5000';
  static const String _defaultOtherUrl = 'http://127.0.0.1:5000';

  // Optional override: flutter run --dart-define=API_BASE_URL=http://192.168.1.45:5000
  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final raw = _apiOverride.isNotEmpty
        ? _apiOverride
        : (kIsWeb
              ? _webBaseUrlFromBrowser()
              : (defaultTargetPlatform == TargetPlatform.android
                    ? _defaultAndroidEmulatorUrl
                    : _defaultOtherUrl));

    // Keep URL joins predictable for "${AppConfig.baseUrl}/products".
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String _webBaseUrlFromBrowser() {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:5000';
  }
}
