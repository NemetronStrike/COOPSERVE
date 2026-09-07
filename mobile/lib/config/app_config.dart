class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'development');

  // Android emulator maps 10.0.2.2 to host machine localhost.
  // Change to LAN IP when testing on a physical device.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
