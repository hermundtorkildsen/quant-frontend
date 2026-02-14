import 'package:flutter/material.dart';
import '../backend/quant_backend.dart';
import '../screens/quant_home_screen.dart';
import 'auth_api.dart';
import 'auth_service.dart';
import 'token_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  late final TokenStore _tokenStore;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();

    final baseUrl = useCloudBackend
        ? 'https://quant-backend-aism.onrender.com'
        : 'http://10.0.2.2:8080';

    _tokenStore = tokenStore; // <-- bruk globalen
    _auth = AuthService(
      api: AuthApi(baseUrl: baseUrl),
      tokenStore: _tokenStore,
    );
  }

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.login(_emailController.text, _passwordController.text);
      if (!mounted) return;

      // Go to app home (existing)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QuantHomeScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.register(_emailController.text, _passwordController.text);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QuantHomeScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logg inn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-post'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passord (min 10 tegn)'),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _doLogin,
                    child: _loading ? const Text('...') : const Text('Login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _doRegister,
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
