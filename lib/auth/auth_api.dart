import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_exceptions.dart';

class AuthApi {
  AuthApi({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Future<String> register({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final res = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw _toApiException(
        res,
        fallback: 'Kunne ikke registrere. Prøv igjen.',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['token'] as String;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw _toApiException(
        res,
        fallback: 'Feil e-post eller passord.',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['token'] as String;
  }

  ApiException _toApiException(http.Response res, {required String fallback}) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        final code = decoded['error'];

        if (msg is String && msg.trim().isNotEmpty) {
          return ApiException(
            msg,
            code: code is String ? code : null,
          );
        }
      }
    } catch (_) {
      // ignore parse errors
    }

    return ApiException(fallback);
  }
}
