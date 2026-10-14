import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../push/push_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'select_clinic_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final dob = TextEditingController();
  final addressLine = TextEditingController();
  final city = TextEditingController();
  final region = TextEditingController();
  final postalCode = TextEditingController();
  final invite = TextEditingController();
  String? error;
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    dob.dispose();
    addressLine.dispose();
    city.dispose();
    region.dispose();
    postalCode.dispose();
    invite.dispose();
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
                    'Create account',
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
                  title: 'Join your clinic',
                  subtitle:
                      'Share your home address next. After you create an account we will show nearby clinics so you can choose where to book.',
                ),
                const SizedBox(height: 28),
                _SectionLabel('Personal details'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: firstName,
                        label: 'First name',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: lastName,
                        label: 'Last name',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: password,
                  label: 'Password',
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
                  controller: dob,
                  label: 'Date of birth',
                  hint: 'YYYY-MM-DD',
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                _SectionLabel('Home address'),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: addressLine,
                  label: 'Street address',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: city,
                  label: 'City',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: region,
                        label: 'State',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: postalCode,
                        label: 'ZIP',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel('Optional'),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: invite,
                  label: 'Invite code',
                  hint: 'If your clinic gave you one',
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: error!),
                ],
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: busy ? 'Creating account…' : 'Create account',
                  busy: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
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
      await widget.auth.register({
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'date_of_birth': dob.text.trim(),
        'address_line': addressLine.text.trim(),
        'city': city.text.trim(),
        'region': region.text.trim(),
        'postal_code': postalCode.text.trim(),
        'invite_code': invite.text.trim().isEmpty ? null : invite.text.trim(),
      });
      await PushService.instance.syncToken(widget.auth);
      if (!mounted) return;
      await AppPageRoute.pushAndRemoveUntil(
        context,
        SelectClinicScreen(
          auth: widget.auth,
          fromRegistration: true,
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.tealSoft,
      ),
    );
  }
}
