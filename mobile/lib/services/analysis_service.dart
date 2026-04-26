import 'dart:convert';

import 'api_client.dart';

class AnalysisService {
  AnalysisService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Get search history for the authenticated user.
  /// Returns {total_searches, offset, limit, history: [...]}
  Future<Map<String, dynamic>> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/api/analysis/history/?limit=$limit&offset=$offset',
      auth: true,
    );

    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final err = json is Map && json['error'] != null
          ? json['error'].toString()
          : res.body;
      throw Exception('Analysis history error: $err');
    }

    return json as Map<String, dynamic>;
  }

  /// Save a new search/analysis entry.
  /// Returns {ok, message, query, category, result_count}
  Future<Map<String, dynamic>> saveSearch({
    required String query,
    String category = '',
    int resultCount = 0,
    List<Map<String, dynamic>> resultsSummary = const [],
  }) async {
    final res = await _client.post(
      '/api/analysis/history/',
      body: {
        'query': query,
        'category': category,
        'result_count': resultCount,
        'results_summary': resultsSummary,
      },
      auth: true,
    );

    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final err = json is Map && json['error'] != null
          ? json['error'].toString()
          : res.body;
      throw Exception('Failed to save analysis: $err');
    }

    return json as Map<String, dynamic>;
  }
}
