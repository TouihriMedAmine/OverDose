import 'dart:convert';

import 'api_client.dart';

class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Send message to chat endpoint with search context.
  /// Returns {user_message, bot_response, timestamp}
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String lastQuery = '',
    List<Map<String, dynamic>> products = const [],
  }) async {
    final res = await _client.post(
      '/api/chat/',
      body: {
        'message': message,
        'last_query': lastQuery,
        'products': products,
      },
    );

    final json = jsonDecode(res.body);
    if (res.statusCode != 200) {
      final err = json is Map && json['error'] != null
          ? json['error'].toString()
          : res.body;
      throw Exception('Chat error: $err');
    }

    return json as Map<String, dynamic>;
  }
}
