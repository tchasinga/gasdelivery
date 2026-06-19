import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// Gatekeeper for actions that require a signed-in customer (e.g. placing an order).
/// Browsing, cart, and product views stay open to guests.
class AuthGatekeeper {
  AuthGatekeeper._();

  /// Returns `true` when the user is authenticated (or just signed in).
  /// Otherwise opens [LoginScreen] and returns `true` only after successful login.
  static Future<bool> requireAuth(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;

    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnAfterLogin: true),
      ),
    );

    return loggedIn == true && context.mounted;
  }
}
