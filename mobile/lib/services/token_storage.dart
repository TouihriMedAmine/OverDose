import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  Future<String?> getAccess() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_access);
  }

  Future<String?> getRefresh() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_refresh);
  }

  Future<void> setTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_access, access);
    await p.setString(_refresh, refresh);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_access);
    await p.remove(_refresh);
  }
}
