import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.auth,
    this.initialEmail,
    this.initialToken,
  });

  final AuthRepository auth;
  final String? initialEmail;
  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController email;
  late final TextEditingController token;
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  String? success;
  bool busy = false;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.initialEmail ?? '');
    token = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                const Expanded(
                  child: Text(
                    'Set new password',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                const AuthHeader(
                  title: 'Choose a new password',
                  subtitle:
                      'Set a new password for this clinic account. Email and token are filled from your reset link when opened in CarePath.',
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: token,
                  label: 'Reset token',
                  hint: 'From the email link',
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: password,
                  label: 'New password',
                  obscureText: obscure,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  suffix: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: confirm,
                  label: 'Confirm password',
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: error!),
                ],
                if (success != null) ...[
                  const SizedBox(height: 16),
                  AuthSuccessBanner(message: success!),
                ],
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: busy ? 'Updating…' : 'Update password',
                  busy: busy,
                  onPressed: success != null ? null : _submit,
                ),
                if (success != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      AppPageRoute.pushAndRemoveUntil(
                        context,
                        LoginScreen(auth: widget.auth),
                        (_) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    child: const Text('Go to sign in'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (password.text != confirm.text) {
      setState(() {
        error = 'Passwords do not match.';
        success = null;
      });
      return;
    }

    setState(() {
      busy = true;
      error = null;
      success = null;
    });

    try {
      final data = await widget.auth.resetPassword(
        email: email.text.trim(),
        token: token.text.trim(),
        password: password.text,
        passwordConfirmation: confirm.text,
      );
      if (!mounted) return;
      setState(() {
        success = (data['message'] as String?) ??
            'Your password has been updated. You can sign in now.';
      });
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
