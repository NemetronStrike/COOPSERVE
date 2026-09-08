import 'package:flutter/foundation.dart';

class AppConfig {
  static const env = String.fromEnvironment(
    'ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  static const String _productionApiUrl = 'https://coopserve-0poc.onrender.com';
  static const String _localApiUrl = 'http://10.0.2.2:8000';

  // Android emulator maps 10.0.2.2 to host machine localhost.
  // Change to LAN IP when testing on a physical device.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: (env == 'production' || kReleaseMode) ? _productionApiUrl : _localApiUrl,
  );
}
