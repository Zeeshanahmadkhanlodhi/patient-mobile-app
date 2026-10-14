import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../api/billing_repository.dart';
import '../api/care_repository.dart';
import '../api/intake_repository.dart';
import '../api/privacy_repository.dart';
import '../api/records_repository.dart';
import '../navigation/app_page_route.dart';
import '../push/push_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import 'billing_screen.dart';
import 'care_screen.dart';
import 'clinic_detail_screen.dart';
import 'documents_screen.dart';
import 'family_screen.dart';
import 'help_screen.dart';
import 'intake_screen.dart';
import 'login_screen.dart';
import 'medications_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'results_screen.dart';
import 'select_clinic_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.auth,
    this.me,
    required this.onRefresh,
  });

  final AuthRepository auth;
  final Map<String, dynamic>? me;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = me?['user'] as Map<String, dynamic>?;
    final preferred = me?['preferred_clinic'] as Map<String, dynamic>?;
    final proxies = ((me?['proxies'] as List<dynamic>?) ?? []).whereType<Map>().toList();
    final name = user?['name']?.toString() ?? 'Your CarePath account';

    return DashboardBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            GestureDetector(
              onTap: () => AppPageRoute.push(context, ProfileScreen(auth: auth, me: me)),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      initialsFor(name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'More',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(name, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Health'),
            const SizedBox(height: 8),
            _group([
              _item(
                context,
                icon: Icons.folder_open_outlined,
                title: 'Medical records',
                subtitle: 'Visits, allergies, vitals',
                onTap: () => AppPageRoute.push(context, RecordsScreen(records: RecordsRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.science_outlined,
                title: 'Lab & results',
                subtitle: 'Released labs and imaging',
                onTap: () => AppPageRoute.push(context, ResultsScreen(records: RecordsRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.medication_outlined,
                title: 'Medications',
                subtitle: 'Taken logs and refill requests',
                onTap: () => AppPageRoute.push(context, MedicationsScreen(care: CareRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.description_outlined,
                title: 'Documents',
                subtitle: 'Notes, immunizations, devices',
                onTap: () => AppPageRoute.push(context, DocumentsScreen(records: RecordsRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.favorite_border_rounded,
                title: 'Care plan',
                subtitle: 'Meds, refills, education',
                onTap: () => AppPageRoute.push(context, CareScreen(care: CareRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.assignment_outlined,
                title: 'Intake & PHQ-9',
                subtitle: 'Questionnaires before visits',
                onTap: () => AppPageRoute.push(context, IntakeScreen(intake: IntakeRepository(auth.client))),
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Account'),
            const SizedBox(height: 8),
            _group([
              _item(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Profile & settings',
                subtitle: 'Contact, password, alerts',
                onTap: () => AppPageRoute.push(context, ProfileScreen(auth: auth, me: me)),
              ),
              _item(
                context,
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Visits and unread messages',
                onTap: () => AppPageRoute.push(context, NotificationsScreen(auth: auth)),
              ),
              _item(
                context,
                icon: Icons.payments_outlined,
                title: 'Billing',
                subtitle: 'Balance, estimates, plans',
                onTap: () => AppPageRoute.push(context, BillingScreen(billing: BillingRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: 'Consents and access log',
                onTap: () => AppPageRoute.push(context, PrivacyScreen(privacy: PrivacyRepository(auth.client))),
              ),
              _item(
                context,
                icon: Icons.local_hospital_outlined,
                title: 'My clinic',
                subtitle: preferred?['name']?.toString() ?? 'Choose where you book',
                onTap: () async {
                  if (preferred != null) {
                    await AppPageRoute.push(
                      context,
                      ClinicDetailScreen(auth: auth, clinic: preferred, isPreferred: true),
                    );
                    return;
                  }
                  final changed = await AppPageRoute.push<bool>(
                    context,
                    SelectClinicScreen(auth: auth),
                  );
                  if (changed == true) await onRefresh();
                },
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Support'),
            const SizedBox(height: 8),
            _group([
              _item(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help & support',
                subtitle: 'FAQs and clinic contact',
                onTap: () => AppPageRoute.push(context, HelpScreen(auth: auth)),
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Family'),
            const SizedBox(height: 8),
            _group([
              _item(
                context,
                icon: Icons.family_restroom_rounded,
                title: 'Family access',
                subtitle: proxies.isEmpty ? 'No linked people yet' : '${proxies.length} linked profile${proxies.length == 1 ? '' : 's'}',
                onTap: () => AppPageRoute.push(
                  context,
                  FamilyScreen(auth: auth, me: me, onChanged: onRefresh),
                ),
                last: true,
              ),
            ]),
            const SizedBox(height: 16),
            const SectionLabel('Session'),
            const SizedBox(height: 8),
            _group([
              _item(
                context,
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'End this session on this device',
                danger: true,
                last: true,
                onTap: () async {
                  await PushService.instance.clearToken(auth);
                  await auth.logout();
                  if (!context.mounted) return;
                  await AppPageRoute.pushAndRemoveUntil(
                    context,
                    LoginScreen(auth: auth),
                    (_) => false,
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return DashboardCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    bool last = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (danger ? AppColors.danger : AppColors.teal).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: danger ? AppColors.danger : AppColors.teal),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: danger ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
