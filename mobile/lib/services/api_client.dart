import 'dart:convert';
import 'dart:io';
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

  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    final detail = json['detail'];
    final msg = detail is String
        ? detail
        : detail is List
            ? ((detail.first as Map)['msg'] ?? 'Request failed')
            : 'Request failed';
    throw ApiException(response.statusCode, msg.toString());
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            _base.replace(path: path),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(0, 'network_error');
    } catch (_) {
      throw const ApiException(0, 'network_error');
    }
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            _base.replace(path: path),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 15));
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(0, 'network_error');
    } catch (_) {
      throw const ApiException(0, 'network_error');
    }
  }
}
