import 'dart:convert';

import 'api_client.dart';

class SearchService {
  SearchService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> search({
    required String q,
    String category = 'auto',
    bool fallback = true,
    bool useLoyalty = true,
  }) async {
    final res = await _client.post(
      '/api/search/',
      body: {
        'q': q,
        'category': category,
        'fallback': fallback,
        'use_loyalty': useLoyalty,
      },
    );
    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final err = json is Map && json['error'] != null ? json['error'].toString() : res.body;
      throw Exception(err);
    }
    return json as Map<String, dynamic>;
  }

  Future<void> recordClick(String title) async {
    if (title.isEmpty) return;
    await _client.post('/api/learning/click/', body: {'title': title});
  }
}
