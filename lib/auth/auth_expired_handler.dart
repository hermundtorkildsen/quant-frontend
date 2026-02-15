import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../auth/token_store.dart';
import '../api/auth_exceptions.dart';
import '../backend/quant_backend.dart'; // for global tokenStore

/// Call this when an API call fails with AuthExpiredException.
/// Clears token and sends user to login (AuthGate), with a snackbar.
Future<void> handleAuthExpired(BuildContext context, {String? message}) async {
  // tokenStore er global i quant_backend.dart – den er already cleared i QuantBackendHttp,
  // men vi kjører den igjen for safety.
  await tokenStore.clear();
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(message ?? 'Økten din er utløpt. Logg inn på nytt.')),
  );

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
  );
}

/// Utility: returns true if it handled the error (AuthExpiredException).
Future<bool> maybeHandleAuthExpired(BuildContext context, Object error) async {
  if (error is AuthExpiredException) {
    await handleAuthExpired(context, message: error.message);
    return true;
  }
  return false;
}
