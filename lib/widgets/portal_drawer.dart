import 'package:flutter/material.dart';

import '../api/appointments_repository.dart';
import '../api/auth_repository.dart';
import '../api/billing_repository.dart';
import '../api/care_repository.dart';
import '../api/intake_repository.dart';
import '../api/privacy_repository.dart';
import '../api/records_repository.dart';
import '../navigation/app_page_route.dart';
import '../push/push_service.dart';
import '../theme/app_colors.dart';
import '../screens/appointments_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/care_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/family_screen.dart';
import '../screens/help_screen.dart';
import '../screens/intake_screen.dart';
import '../screens/login_screen.dart';
import '../screens/medications_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/results_screen.dart';
import '../screens/select_clinic_screen.dart';
import 'dashboard_widgets.dart';

class PortalDrawer extends StatelessWidget {
  const PortalDrawer({
    super.key,
    required this.auth,
    required this.me,
    required this.selectedTab,
    required this.onSelectTab,
    required this.onRefresh,
  });

  final AuthRepository auth;
  final Map<String, dynamic>? me;
  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final user = me?['user'] as Map<String, dynamic>?;
    final preferred = me?['preferred_clinic'] as Map<String, dynamic>?;
    final unread = (me?['unread_messages'] as num?)?.toInt() ?? 0;
    final status = user?['identity_status']?.toString() ?? 'unknown';
    final name = user?['name']?.toString() ?? 'Patient';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: InkWell(
                onTap: () => _push(context, ProfileScreen(auth: auth, me: me)),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          initialsFor(name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preferred?['name']?.toString() ?? 'Choose a clinic',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                StatusPill(label: status.replaceAll('_', ' '), tone: PillTone.info),
                                if (unread > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      '$unread unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                children: [
                  _section('Navigate'),
                  _tabItem(context, Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                  _tabItem(context, Icons.folder_open_outlined, Icons.folder_rounded, 'Records', 1),
                  _tabItem(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    Icons.chat_bubble_rounded,
                    'Inbox',
                    2,
                    badge: unread > 0 ? '$unread' : null,
                  ),
                  _tabItem(context, Icons.apps_outlined, Icons.apps_rounded, 'More', 3),
                  _section('Health'),
                  _routeItem(
                    context,
                    Icons.calendar_month_outlined,
                    'Book a visit',
                    () => _push(
                      context,
                      AppointmentsScreen(
                        appointments: AppointmentsRepository(auth.client),
                        auth: auth,
                      ),
                    ),
                  ),
                  _routeItem(
                    context,
                    Icons.folder_open_outlined,
                    'Medical records',
                    () {
                      Navigator.of(context).pop();
                      onSelectTab(1);
                    },
                  ),
                  _routeItem(
                    context,
                    Icons.science_outlined,
                    'Lab & results',
                    () => _push(context, ResultsScreen(records: RecordsRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.medication_outlined,
                    'Medications',
                    () => _push(context, MedicationsScreen(care: CareRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.description_outlined,
                    'Documents',
                    () => _push(context, DocumentsScreen(records: RecordsRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.favorite_border_rounded,
                    'Care plan',
                    () => _push(context, CareScreen(care: CareRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.assignment_outlined,
                    'Intake & PHQ-9',
                    () => _push(context, IntakeScreen(intake: IntakeRepository(auth.client))),
                  ),
                  _section('Account'),
                  _routeItem(
                    context,
                    Icons.person_outline_rounded,
                    'Profile & settings',
                    () => _push(context, ProfileScreen(auth: auth, me: me)),
                  ),
                  _routeItem(
                    context,
                    Icons.notifications_none_rounded,
                    'Notifications',
                    () => _push(context, NotificationsScreen(auth: auth)),
                  ),
                  _routeItem(
                    context,
                    Icons.payments_outlined,
                    'Billing',
                    () => _push(context, BillingScreen(billing: BillingRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.shield_outlined,
                    'Privacy',
                    () => _push(context, PrivacyScreen(privacy: PrivacyRepository(auth.client))),
                  ),
                  _routeItem(
                    context,
                    Icons.local_hospital_outlined,
                    'My clinic',
                    () async {
                      Navigator.of(context).pop();
                      final changed = await AppPageRoute.push<bool>(
                        context,
                        SelectClinicScreen(auth: auth),
                      );
                      if (changed == true) await onRefresh();
                    },
                  ),
                  _routeItem(
                    context,
                    Icons.family_restroom_rounded,
                    'Family access',
                    () => _push(context, FamilyScreen(auth: auth, me: me, onChanged: onRefresh)),
                  ),
                  _section('Support'),
                  _routeItem(
                    context,
                    Icons.help_outline_rounded,
                    'Help & support',
                    () => _push(context, HelpScreen(auth: auth)),
                  ),
                  _section('Session'),
                  _routeItem(
                    context,
                    Icons.logout_rounded,
                    'Sign out',
                    () async {
                      Navigator.of(context).pop();
                      await PushService.instance.clearToken(auth);
                      await auth.logout();
                      if (!context.mounted) return;
                      await AppPageRoute.pushAndRemoveUntil(
                        context,
                        LoginScreen(auth: auth),
                        (_) => false,
                      );
                    },
                    danger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _tabItem(
    BuildContext context,
    IconData icon,
    IconData selectedIcon,
    String label,
    int index, {
    String? badge,
  }) {
    final selected = selectedTab == index;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: AppColors.tealMist,
      leading: Icon(selected ? selectedIcon : icon, size: 20, color: selected ? AppColors.teal : AppColors.ink),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.tealDeep : AppColors.ink,
        ),
      ),
      trailing: badge == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10.5),
              ),
            ),
      onTap: () {
        Navigator.of(context).pop();
        onSelectTab(index);
      },
    );
  }

  Widget _routeItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 20, color: danger ? AppColors.danger : AppColors.ink),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: danger ? AppColors.danger : AppColors.ink,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _push(BuildContext context, Widget screen) async {
    Navigator.of(context).pop();
    await AppPageRoute.push(context, screen);
    await onRefresh();
  }
}
