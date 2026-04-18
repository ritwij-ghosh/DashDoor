import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kAnonymousUserIdKey = 'dashdoor_anonymous_user_id_v1';

/// Stable opaque id for this install, used as Composio `user_id` until real auth exists.
class AnonymousUserId {
  AnonymousUserId._();

  static const _uuid = Uuid();

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kAnonymousUserIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'anon_${_uuid.v4()}';
    await prefs.setString(_kAnonymousUserIdKey, id);
    return id;
  }
}
