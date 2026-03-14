import 'package:flutter/material.dart';
import '../backend/quant_backend.dart';
import '../screens/quant_home_screen.dart';
import 'auth_api.dart';
import 'auth_service.dart';
import 'token_store.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

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

    _tokenStore = tokenStore;
    _auth = AuthService(
      api: AuthApi(baseUrl: baseUrl),
      tokenStore: _tokenStore,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final username = _usernameController.text.trim().toLowerCase();

      if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
        throw Exception('Brukernavn må være 3–20 tegn og kun a-z, 0-9 eller _.');
      }
      if (password.length < 10) {
        throw Exception('Passord må være minst 10 tegn.');
      }

      await _auth.register(email, password, username);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const QuantHomeScreen()),
            (_) => false,
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
      appBar: AppBar(title: const Text('Opprett konto')),
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
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Brukernavn (3–20, a-z 0-9 _)',
              ),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _doRegister,
                child: _loading
                    ? const Text('...')
                    : const Text('Opprett konto'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Tilbake til innlogging'),
            ),
          ],
        ),
      ),
    );
  }
}
