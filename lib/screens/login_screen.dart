import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/auth_repository.dart';
import '../deep_links/deep_link_service.dart';
import '../navigation/app_page_route.dart';
import '../push/push_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final portalUrl = TextEditingController(text: ApiClient.defaultBaseUrl);
  final tenantSlug = TextEditingController(text: ApiClient.defaultTenantSlug);
  String? error;
  bool busy = false;
  bool obscure = true;
  bool showClinicSettings = false;

  @override
  void initState() {
    super.initState();
    _loadEndpoint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.flushPending();
    });
  }

  Future<void> _loadEndpoint() async {
    final client = widget.auth.client;
    final url = await client.baseUrl();
    final slug = await client.tenantSlug();
    if (!mounted) return;
    setState(() {
      portalUrl.text = url;
      tenantSlug.text = slug;
    });
  }

  Future<void> _persistEndpoint() {
    return widget.auth.client.saveEndpoint(
      baseUrl: portalUrl.text,
      tenantSlug: tenantSlug.text,
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    portalUrl.dispose();
    tenantSlug.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          AuthHeader(
            title: 'Welcome back',
            subtitle: 'Sign in with the same clinic account you use on the web.',
            onBrandLongPress: () {
              setState(() => showClinicSettings = !showClinicSettings);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    showClinicSettings
                        ? 'Clinic connection settings unlocked.'
                        : 'Clinic connection settings hidden.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: password,
            label: 'Password',
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            suffix: IconButton(
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.muted,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy
                  ? null
                  : () {
                      AppPageRoute.push(
                        context,
                        ForgotPasswordScreen(
                          auth: widget.auth,
                          initialEmail: email.text.trim(),
                        ),
                      );
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealSoft,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          if (showClinicSettings) ...[
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                iconColor: AppColors.teal,
                collapsedIconColor: AppColors.muted,
                title: const Text(
                  'Clinic / API',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                subtitle: const Text(
                  'Developer / clinic setup only.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                children: [
                  AuthTextField(
                    controller: portalUrl,
                    label: 'Portal address',
                    hint: 'http://192.168.1.20:8010',
                    helper: 'Phone: laptop LAN IP. Android emulator: 10.0.2.2:8010',
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: tenantSlug,
                    label: 'Clinic slug',
                    hint: 'riverside',
                    autocorrect: false,
                  ),
                ],
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            AuthErrorBanner(message: error!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: busy ? 'Signing in…' : 'Sign in',
            busy: busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    await _persistEndpoint();
                    if (!context.mounted) return;
                    AppPageRoute.push(context, RegisterScreen(auth: widget.auth));
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _persistEndpoint();
      await widget.auth.login(email.text.trim(), password.text);
      await PushService.instance.syncToken(widget.auth);
      if (!mounted) return;
      await AppPageRoute.pushReplacement(context, HomeScreen(auth: widget.auth));
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
