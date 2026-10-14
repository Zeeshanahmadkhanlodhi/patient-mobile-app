import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.auth, this.initialEmail});

  final AuthRepository auth;
  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController email;
  String? error;
  String? success;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    email.dispose();
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
                    'Reset password',
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
                  title: 'Forgot password?',
                  subtitle:
                      'Enter your clinic email. We will send a reset link that opens CarePath with your details filled in.',
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
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
                  label: busy ? 'Sending…' : 'Send reset link',
                  busy: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          AppPageRoute.push(
                            context,
                            ResetPasswordScreen(
                              auth: widget.auth,
                              initialEmail: email.text.trim(),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  child: const Text('I already have a reset token'),
                ),
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final value = email.text.trim();
    if (value.isEmpty) {
      setState(() {
        error = 'Enter the email for your clinic account.';
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
      final data = await widget.auth.forgotPassword(value);
      if (!mounted) return;
      setState(() {
        success = (data['message'] as String?) ??
            'If that email is registered at this clinic, we sent a reset link.';
      });
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
