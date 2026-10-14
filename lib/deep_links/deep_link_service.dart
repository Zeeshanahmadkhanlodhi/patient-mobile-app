import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../screens/reset_password_screen.dart';

/// Handles CarePath password-reset deep links:
/// `carepath://reset-password?token=...&email=...&tenant=riverside`
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  AuthRepository? _auth;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pending;

  Future<void> start({
    required AuthRepository auth,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _auth = auth;
    _navigatorKey = navigatorKey;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (_) {
      // Ignore cold-start parse failures; URI stream still works.
    }

    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  Future<void> flushPending() async {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    await _handle(pending);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _handle(Uri uri) async {
    final reset = _parseReset(uri);
    if (reset == null) return;

    final auth = _auth;
    final nav = _navigatorKey?.currentState;
    if (auth == null) return;

    if (reset.tenant != null && reset.tenant!.isNotEmpty) {
      final baseUrl = await auth.client.baseUrl();
      await auth.client.saveEndpoint(baseUrl: baseUrl, tenantSlug: reset.tenant!);
    }

    if (nav == null) {
      _pending = uri;
      return;
    }

    nav.push(
      AppPageRoute(
        builder: (_) => ResetPasswordScreen(
          auth: auth,
          initialEmail: reset.email,
          initialToken: reset.token,
        ),
      ),
    );
  }

  _ResetLink? _parseReset(Uri uri) {
    final isCarePathScheme = uri.scheme == 'carepath';
    final isHttpsBridge = (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.contains('app-link/reset-password');
    final isCustomPath = uri.host == 'reset-password' ||
        uri.path == '/reset-password' ||
        uri.path.endsWith('/reset-password');

    if (!isCarePathScheme && !isHttpsBridge && !isCustomPath) {
      return null;
    }

    final token = uri.queryParameters['token']?.trim() ?? '';
    final email = uri.queryParameters['email']?.trim() ?? '';
    if (token.isEmpty || email.isEmpty) {
      return null;
    }

    return _ResetLink(
      token: token,
      email: email,
      tenant: uri.queryParameters['tenant']?.trim(),
    );
  }
}

class _ResetLink {
  const _ResetLink({
    required this.token,
    required this.email,
    this.tenant,
  });

  final String token;
  final String email;
  final String? tenant;
}
