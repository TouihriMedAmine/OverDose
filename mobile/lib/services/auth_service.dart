import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  factory AuthService({TokenStorage? storage, ApiClient? client}) {
    final ts = storage ?? TokenStorage();
    return AuthService._(ts, client ?? ApiClient(storage: ts));
  }

  AuthService._(this._storage, this._client);

  final TokenStorage _storage;
  final ApiClient _client;
  final String _base = AppConfig.apiBaseUrl;

  Future<void> login(String username, String password) async {
    final uri = Uri.parse('$_base/api/auth/login/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      final err = _parseError(res.body);
      throw Exception(err);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || refresh == null) {
      throw Exception('Invalid login response');
    }
    await _storage.setTokens(access, refresh);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? dateOfBirth,
    String? gender,
    String diseases = '',
  }) async {
    final uri = Uri.parse('$_base/api/auth/register/');
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'diseases': diseases,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_parseError(res.body));
    }
    await login(username, password);
  }

  Future<UserModel?> loadMe() async {
    final t = await _storage.getAccess();
    if (t == null || t.isEmpty) return null;
    try {
      final res = await _client.get('/api/auth/me/');
      if (res.statusCode != 200) return null;
      return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      // Backend unreachable or network error: treat as logged-out for now.
      return null;
    }
  }

  /// PATCH /api/auth/me/ — email, optional profile fields. Username is not editable.
  Future<UserModel> updateProfile({
    required String email,
    String? dateOfBirth,
    String? gender,
    String diseases = '',
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'diseases': diseases,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    };
    final res = await _client.patch('/api/auth/me/', body: body);
    if (res.statusCode != 200) {
      throw Exception(_parseError(res.body));
    }
    return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.clear();

  String _parseError(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map<String, dynamic>) {
        if (j['detail'] != null) return j['detail'].toString();
        return j.entries.map((e) => '${e.key}: ${e.value}').join(' ');
      }
    } catch (_) {}
    return body.isEmpty ? 'Request failed' : body;
  }
}
