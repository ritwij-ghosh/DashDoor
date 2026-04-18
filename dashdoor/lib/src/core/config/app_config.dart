// Fill in your credentials here after setup.
// See SETUP.md or the chat for instructions.
class AppConfig {
  AppConfig._();

  // Supabase — https://supabase.com → Project Settings → API
  static const supabaseUrl = 'https://your-project-id.supabase.co';
  static const supabaseAnonKey = 'your-supabase-anon-key';

  // FastAPI backend URL
  // Local development (iOS sim / web): 'http://localhost:8000'
  // Android emulator: 'http://10.0.2.2:8000'
  // Physical device: your machine's local IP, e.g. 'http://192.168.1.x:8000'
  static const apiBaseUrl = 'http://localhost:8000';
}
