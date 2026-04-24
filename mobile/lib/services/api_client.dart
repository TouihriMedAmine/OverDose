import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'token_storage.dart';

/// JWT-aware HTTP client for the Django API.
class ApiClient {
  ApiClient({TokenStorage? storage}) : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;
  final String _base = AppConfig.apiBaseUrl;

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$p');
  }

  Future<http.Response> get(String path, {bool auth = true}) async {
    return _send('GET', path, auth: auth);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final t = await _storage.getAccess();
      if (t != null && t.isNotEmpty) {
        headers['Authorization'] = 'Bearer $t';
      }
    }

    Future<http.Response> once() async {
      final uri = _uri(path);
      final b = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri, headers: headers, body: b);
        case 'PATCH':
          return http.patch(uri, headers: headers, body: b);
        default:
          throw UnsupportedError(method);
      }
    }

    var res = await once();
    if (res.statusCode == 401 && auth) {
      final newAccess = await _refreshAccess();
      if (newAccess != null) {
        headers['Authorization'] = 'Bearer $newAccess';
        res = await once();
      }
    }
    return res;
  }

  Future<String?> _refreshAccess() async {
    final r = await _storage.getRefresh();
    if (r == null || r.isEmpty) return null;
    final uri = _uri('/api/auth/token/refresh/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': r}),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final access = data['access'] as String?;
    if (access == null) return null;
    await _storage.setTokens(access, r);
    return access;
  }
}
