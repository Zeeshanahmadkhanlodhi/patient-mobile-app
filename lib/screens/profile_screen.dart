import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import 'forgot_password_screen.dart';
import 'select_clinic_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.auth, this.me});

  final AuthRepository auth;
  final Map<String, dynamic>? me;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? me;
  bool loading = true;
  bool pushEnabled = true;
  bool visitReminders = true;
  bool messageAlerts = true;
  String? error;

  @override
  void initState() {
    super.initState();
    me = widget.me;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      loading = me == null;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final fresh = await widget.auth.me();
      if (!mounted) return;
      setState(() {
        me = fresh;
        pushEnabled = prefs.getBool('pref_push_enabled') ?? true;
        visitReminders = prefs.getBool('pref_visit_reminders') ?? true;
        messageAlerts = prefs.getBool('pref_message_alerts') ?? true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _setPref(String key, bool value, void Function(bool) apply) async {
    await AppHaptics.selection();
    apply(value);
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final user = me?['user'] as Map<String, dynamic>?;
    final identity = me?['identity'] as Map<String, dynamic>?;
    final preferred = me?['preferred_clinic'] as Map<String, dynamic>?;
    final name = user?['name']?.toString() ?? 'Patient';
    final email = user?['email']?.toString() ?? '—';
    final phone = user?['phone']?.toString() ?? user?['mobile']?.toString() ?? '—';
    final status = user?['identity_status']?.toString() ?? 'unknown';
    final linked = identity?['openemr_patient_uuid'] != null;

    return FeatureShell(
      title: 'Profile',
      subtitle: 'Account & preferences',
      child: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : RefreshIndicator(
              color: AppColors.teal,
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  DashboardCard(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            initialsFor(name),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              const SizedBox(height: 4),
                              Text(email, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StatusPill(
                                    label: linked ? 'Chart linked' : 'Chart pending',
                                    tone: linked ? PillTone.success : PillTone.warning,
                                  ),
                                  const SizedBox(width: 6),
                                  StatusPill(label: status.replaceAll('_', ' '), tone: PillTone.info),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Contact'),
                  const SizedBox(height: 8),
                  DashboardCard(
                    child: Column(
                      children: [
                        InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: email),
                        InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone.isEmpty ? '—' : phone),
                        InfoRow(
                          icon: Icons.local_hospital_outlined,
                          label: 'Preferred clinic',
                          value: preferred?['name']?.toString() ?? 'Not set',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Security'),
                  const SizedBox(height: 8),
                  DashboardCard(
                    elevated: false,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.lock_reset_rounded,
                          title: 'Reset password',
                          subtitle: 'Send a secure reset link to your email',
                          onTap: () => AppPageRoute.push(
                            context,
                            ForgotPasswordScreen(auth: widget.auth),
                          ),
                        ),
                        _ActionTile(
                          icon: Icons.apartment_rounded,
                          title: 'Change clinic',
                          subtitle: preferred?['name']?.toString() ?? 'Choose where you book',
                          last: true,
                          onTap: () async {
                            final changed = await AppPageRoute.push<bool>(
                              context,
                              SelectClinicScreen(auth: widget.auth),
                            );
                            if (changed == true) await _bootstrap();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Notifications'),
                  const SizedBox(height: 8),
                  DashboardCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Allow CarePath alerts on this device'),
                          value: pushEnabled,
                          activeThumbColor: AppColors.teal,
                          onChanged: (v) => _setPref('pref_push_enabled', v, (x) => pushEnabled = x),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Visit reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Upcoming appointments and check-in'),
                          value: visitReminders,
                          activeThumbColor: AppColors.teal,
                          onChanged: (v) => _setPref('pref_visit_reminders', v, (x) => visitReminders = x),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Message alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('New replies from your clinic'),
                          value: messageAlerts,
                          activeThumbColor: AppColors.teal,
                          onChanged: (v) => _setPref('pref_message_alerts', v, (x) => messageAlerts = x),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
