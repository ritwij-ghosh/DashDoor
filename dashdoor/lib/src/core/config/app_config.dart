/// Runtime configuration for the DashDoor app.
///
/// All values can be overridden at build/run time with `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=https://my-tunnel.ngrok-free.app \
///               --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=ey...
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────
  // https://supabase.com → Project Settings → API
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-id.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-supabase-anon-key',
  );

  // ── FastAPI backend ──────────────────────────────────────────────────
  // Defaults to an ngrok tunnel so physical devices can hit the local
  // backend without changing code. Override with --dart-define=API_BASE_URL
  // for new tunnels, staging, or prod.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://2b68-2610-148-205a-0-289e-dc8e-812c-c6be.ngrok-free.app',
  );

  /// True when `apiBaseUrl` points at an ngrok tunnel so we can add the
  /// `ngrok-skip-browser-warning` header (required on free plans).
  static bool get isNgrok => apiBaseUrl.contains('ngrok');
}
