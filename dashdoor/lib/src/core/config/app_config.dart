/// Runtime configuration (override via `--dart-define=KEY=value`).
class AppConfig {
  AppConfig._();

  /// Base URL for the Healthy Autopilot API (Composio proxy and future endpoints).
  /// Android emulator: use `http://10.0.2.2:PORT` or `adb reverse tcp:3847 tcp:3847` with 127.0.0.1.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3847',
  );
}
