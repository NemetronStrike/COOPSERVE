import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final Uri _base = Uri.parse(AppConfig.apiBaseUrl);

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          _base.replace(path: path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final detail = json['detail'];
    final message = detail is String
        ? detail
        : detail is List
            ? (detail.first['msg'] ?? 'Request failed')
            : 'Request failed';

    throw ApiException(response.statusCode, message.toString());
  }
}
