import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  AuthApi({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Future<String> register({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final res = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Register failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['token'] as String;
  }

  Future<String> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['token'] as String;
  }
}
