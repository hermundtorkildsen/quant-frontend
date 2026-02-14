import '../auth/token_store.dart';
import 'auth_api.dart';

class AuthService {
  AuthService({required this.api, required this.tokenStore});

  final AuthApi api;
  final TokenStore tokenStore;

  Future<void> register(String email, String password) async {
    final token = await api.register(email: email, password: password);
    await tokenStore.setToken(token);
  }

  Future<void> login(String email, String password) async {
    final token = await api.login(email: email, password: password);
    await tokenStore.setToken(token);
  }

  Future<void> logout() => tokenStore.clear();
}
