import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_client.dart';

class ScanService {
  ScanService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  final String _base = AppConfig.apiBaseUrl;

  /// Upload image for barcode/QR code recognition.
  /// Returns {detected, barcode_type, barcode_value, confidence, product_info}
  Future<Map<String, dynamic>> recognizeBarcode(Uint8List imageBytes) async {
    final uri = Uri.parse('$_base/api/scan/recognize/');
    
    // Convert image to base64
    final base64Image = base64Encode(imageBytes);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Get auth token if available
    final token = await _client.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'image': base64Image,
          'format': 'base64',
        }),
      );

      final json = jsonDecode(res.body);
      if (res.statusCode != 200) {
        final err = json is Map && json['error'] != null
            ? json['error'].toString()
            : res.body;
        throw Exception('Barcode recognition failed: $err');
      }

      return json as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Scan service error: $e');
    }
  }
}
