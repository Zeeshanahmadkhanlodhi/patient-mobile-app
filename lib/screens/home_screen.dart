import 'package:flutter/material.dart';

import '../api/appointments_repository.dart';
import '../api/auth_repository.dart';
import '../api/billing_repository.dart';
import '../api/care_repository.dart';
import '../api/intake_repository.dart';
import '../api/messages_repository.dart';
import '../api/privacy_repository.dart';
import '../api/records_repository.dart';
import '../navigation/app_page_route.dart';
import '../push/push_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/care_path_dock.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/fade_indexed_stack.dart';
import '../widgets/portal_drawer.dart';
import 'appointments_screen.dart';
import 'billing_screen.dart';
import 'care_screen.dart';
import 'intake_screen.dart';
import 'messages_screen.dart';
import 'more_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'select_clinic_screen.dart';
import 'visit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, this.initialTab = 0});

  final AuthRepository auth;
  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int tab;
  Widget? _recordsTab;
  Widget? _messagesTab;
  Map<String, dynamic>? me;
  List<Map<String, dynamic>> visits = [];
  Map<String, dynamic>? billing;
  Map<String, dynamic>? intake;
  String? error;
  bool loading = true;
  bool refreshing = false;
  bool checkingIn = false;

  Widget get recordsTab => _recordsTab ??= RecordsScreen(
        records: RecordsRepository(widget.auth.client),
      );

  Widget get messagesTab => _messagesTab ??= MessagesScreen(
        messages: MessagesRepository(widget.auth.client),
      );

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
    // Touch getters so tabs exist before first build / after hot reload.
    recordsTab;
    messagesTab;
    _load();
    PushService.instance.syncToken(widget.auth);
  }

  @override
  void reassemble() {
    super.reassemble();
    _recordsTab ??= RecordsScreen(records: RecordsRepository(widget.auth.client));
    _messagesTab ??= MessagesScreen(messages: MessagesRepository(widget.auth.client));
  }

  Future<void> _load() async {
    setState(() {
      if (me == null) loading = true;
      refreshing = me != null;
      error = null;
    });

    try {
      final appointments = AppointmentsRepository(widget.auth.client);
      final billingRepo = BillingRepository(widget.auth.client);
      final intakeRepo = IntakeRepository(widget.auth.client);

      final results = await Future.wait([
        widget.auth.me(),
        appointments.list(),
        billingRepo.show(),
        intakeRepo.show(),
      ]);

      final meData = results[0] as Map<String, dynamic>;
      final visitRows = <Map<String, dynamic>>[
        for (final row in (results[1] as List<dynamic>))
          if (row is Map) Map<String, dynamic>.from(row),
      ];

      if (!mounted) return;
      setState(() {
        me = meData;
        visits = visitRows;
        billing = results[2] as Map<String, dynamic>;
        intake = results[3] as Map<String, dynamic>;
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
        refreshing = false;
      });
    }
  }

  Future<void> _checkIn(Map<String, dynamic> visit) async {
    final id = visit['id'];
    if (id is! int) return;
    await AppHaptics.action();
    setState(() => checkingIn = true);
    try {
      await AppointmentsRepository(widget.auth.client).checkIn(id);
      await AppHaptics.success();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are checked in.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => checkingIn = false);
    }
  }

  void _selectTab(int index) {
    if (tab == index) {
      if (index == 0) _load();
      return;
    }
    AppHaptics.selection();
    setState(() => tab = index);
    if (index == 0) _load();
  }

  Future<void> _openAppointments() async {
    await AppHaptics.action();
    await _open(
      AppointmentsScreen(
        appointments: AppointmentsRepository(widget.auth.client),
        auth: widget.auth,
      ),
    );
  }

  void _openRecords() => _selectTab(1);
  void _openMessages() => _selectTab(2);
  void _openMore() => _selectTab(3);

  Future<void> _open(Widget screen) async {
    await AppPageRoute.push(context, screen);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = (me?['unread_messages'] as num?)?.toInt() ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: AppColors.cream,
      drawer: PortalDrawer(
        auth: widget.auth,
        me: me,
        selectedTab: tab,
        onSelectTab: _selectTab,
        onRefresh: _load,
      ),
      body: FadeIndexedStack(
        index: tab,
        children: [
          _DashboardTab(
            loading: loading,
            refreshing: refreshing,
            error: error,
            me: me,
            visits: visits,
            billing: billing,
            intake: intake,
            checkingIn: checkingIn,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            onOpenProfile: () => _open(ProfileScreen(auth: widget.auth, me: me)),
            onOpenNotifications: () => _open(NotificationsScreen(auth: widget.auth)),
            onOpenVisit: (visit) async {
              final changed = await AppPageRoute.push<bool>(
                context,
                VisitDetailScreen(
                  appointments: AppointmentsRepository(widget.auth.client),
                  visit: visit,
                ),
              );
              if (changed == true) await _load();
            },
            onRefresh: _load,
            onCheckIn: _checkIn,
            onOpenAppointments: _openAppointments,
            onOpenMessages: _openMessages,
            onOpenMore: _openMore,
            onOpenRecords: _openRecords,
            onOpenCare: () => _open(CareScreen(care: CareRepository(widget.auth.client))),
            onOpenBilling: () => _open(BillingScreen(billing: BillingRepository(widget.auth.client))),
            onOpenPrivacy: () => _open(PrivacyScreen(privacy: PrivacyRepository(widget.auth.client))),
            onOpenIntake: () => _open(IntakeScreen(intake: IntakeRepository(widget.auth.client))),
            onChangeClinic: () async {
              final changed = await AppPageRoute.push<bool>(
                context,
                SelectClinicScreen(auth: widget.auth),
              );
              if (changed == true) await _load();
            },
            onUseNearest: () async {
              await widget.auth.useNearestClinic();
              await _load();
            },
          ),
          recordsTab,
          messagesTab,
          MoreScreen(auth: widget.auth, me: me, onRefresh: _load),
        ],
      ),
      bottomNavigationBar: CarePathDock(
        index: tab,
        unread: unread,
        onChanged: _selectTab,
        onBook: _openAppointments,
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.loading,
    required this.refreshing,
    required this.error,
    required this.me,
    required this.visits,
    required this.billing,
    required this.intake,
    required this.checkingIn,
    required this.onOpenDrawer,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onOpenVisit,
    required this.onRefresh,
    required this.onCheckIn,
    required this.onOpenAppointments,
    required this.onOpenMessages,
    required this.onOpenMore,
    required this.onOpenRecords,
    required this.onOpenCare,
    required this.onOpenBilling,
    required this.onOpenPrivacy,
    required this.onOpenIntake,
    required this.onChangeClinic,
    required this.onUseNearest,
  });

  final bool loading;
  final bool refreshing;
  final String? error;
  final Map<String, dynamic>? me;
  final List<Map<String, dynamic>> visits;
  final Map<String, dynamic>? billing;
  final Map<String, dynamic>? intake;
  final bool checkingIn;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final Future<void> Function(Map<String, dynamic> visit) onOpenVisit;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic> visit) onCheckIn;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenMore;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenCare;
  final VoidCallback onOpenBilling;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenIntake;
  final Future<void> Function() onChangeClinic;
  final Future<void> Function() onUseNearest;

  @override
  Widget build(BuildContext context) {
    if (loading && me == null) {
      return const DashboardBackground(
        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    if (me == null) {
      return DashboardBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error ?? 'Unable to load your dashboard.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRefresh, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }

    final user = me?['user'] as Map<String, dynamic>?;
    final identity = me?['identity'] as Map<String, dynamic>?;
    final preferred = me?['preferred_clinic'] as Map<String, dynamic>?;
    final nearest = me?['nearest_clinic'] as Map<String, dynamic>?;
    final unread = (me?['unread_messages'] as num?)?.toInt() ?? 0;
    final name = user?['name']?.toString() ?? 'there';
    final first = name.split(' ').first;
    final status = user?['identity_status']?.toString() ?? 'unknown';
    final linked = identity?['openemr_patient_uuid'] != null;
    final nextVisit = visits.isNotEmpty ? visits.first : null;
    final dueCents = (billing?['due_cents'] as num?)?.toInt() ?? 0;
    final balance = billing?['balance']?.toString() ?? '0.00';
    final latestIntake = intake?['latest'] as Map<String, dynamic>?;
    final nearestIsPreferred = nearest != null &&
        preferred != null &&
        nearest['id']?.toString() == preferred['id']?.toString();

    final needs = <Widget>[];
    if (unread > 0) {
      needs.add(NeedTile(
        icon: Icons.mail_outline_rounded,
        title: unread == 1 ? '1 unread message' : '$unread unread messages',
        detail: 'Your clinic sent something that needs a look.',
        action: 'Open',
        onTap: onOpenMessages,
      ));
    }
    if (!linked || status == 'unverified' || status == 'pending') {
      needs.add(NeedTile(
        icon: Icons.badge_outlined,
        title: 'Chart confirmation pending',
        detail: 'The clinic is still linking your portal account to the EMR.',
        action: 'Details',
        onTap: onOpenMore,
      ));
    }
    if (dueCents > 0) {
      needs.add(NeedTile(
        icon: Icons.payments_outlined,
        title: 'Balance due \$$balance',
        detail: 'Pay online or start a payment plan.',
        action: 'Pay',
        onTap: onOpenBilling,
      ));
    }
    if (latestIntake == null) {
      needs.add(NeedTile(
        icon: Icons.assignment_outlined,
        title: 'Intake not completed',
        detail: 'Finish PHQ-9 before your next visit.',
        action: 'Start',
        onTap: onOpenIntake,
      ));
    }

    return DashboardBackground(
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onOpenProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        initialsFor(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(first),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preferred?['name']?.toString() ?? 'CarePath',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onOpenNotifications,
                    visualDensity: VisualDensity.compact,
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      smallSize: 8,
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 22),
                    ),
                  ),
                  IconButton(
                    onPressed: onOpenDrawer,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 22),
                  ),
                  if (refreshing)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StatusPill(
                    label: linked ? 'Chart linked' : 'Chart pending',
                    tone: linked ? PillTone.success : PillTone.warning,
                  ),
                  const SizedBox(width: 6),
                  StatusPill(
                    label: status.replaceAll('_', ' '),
                    tone: status == 'verified' ? PillTone.success : PillTone.info,
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 6),
                    StatusPill(label: '$unread unread', tone: PillTone.info),
                  ],
                  if (dueCents > 0) ...[
                    const SizedBox(width: 6),
                    StatusPill(label: '\$$balance due', tone: PillTone.warning),
                  ],
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            if (needs.isNotEmpty) ...[
              const SizedBox(height: 18),
              const SectionLabel('Needs attention'),
              const SizedBox(height: 8),
              ...needs.map((tile) => Padding(padding: const EdgeInsets.only(bottom: 8), child: tile)),
            ],
            const SizedBox(height: 16),
            SectionLabel(
              'Next visit',
              trailing: TextButton(
                onPressed: onOpenAppointments,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.teal,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 6),
            if (nextVisit == null)
              DashboardCard(
                onTap: onOpenAppointments,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.tealMist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nothing booked',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Find a nearby clinic and book in seconds.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: onOpenAppointments,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Book'),
                    ),
                  ],
                ),
              )
            else
              DashboardCard(
                color: AppColors.teal,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nextVisit['provider_name']?.toString() ?? 'Upcoming visit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (nextVisit['checked_in'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Checked in',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatVisitWhen(nextVisit['starts_at']?.toString()),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13.5),
                    ),
                    if ((nextVisit['facility_name'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        nextVisit['facility_name'].toString(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (canCheckInVisit(nextVisit))
                          FilledButton(
                            onPressed: checkingIn ? null : () => onCheckIn(nextVisit),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.tealDeep,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(checkingIn ? 'Checking in…' : 'Check in'),
                          ),
                        if (canCheckInVisit(nextVisit)) const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => onOpenVisit(nextVisit),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Inbox',
                    value: unread > 0 ? '$unread unread' : 'Clear',
                    onTap: onOpenMessages,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Billing',
                    value: dueCents > 0 ? '\$$balance' : '\$0.00',
                    onTap: onOpenBilling,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    icon: Icons.assignment_outlined,
                    label: 'Intake',
                    value: latestIntake == null ? 'Due' : 'Done',
                    onTap: onOpenIntake,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionLabel(
              'Clinic',
              trailing: TextButton(
                onPressed: onChangeClinic,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.teal,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 6),
            DashboardCard(
              elevated: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tealMist,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.local_hospital_outlined, color: AppColors.teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferred?['name']?.toString() ?? 'No preferred clinic',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                        ),
                        if (nearest != null)
                          Text(
                            nearestIsPreferred
                                ? (nearest['reason']?.toString() ?? 'Nearest to your address')
                                : 'Nearest: ${nearest['name']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (nearest != null && !nearestIsPreferred)
                    TextButton(
                      onPressed: onUseNearest,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.teal,
                      ),
                      child: const Text('Use nearest'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Shortcuts'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ShortcutChip(
                    icon: Icons.calendar_month_outlined,
                    label: 'Book',
                    badge: visits.isEmpty ? null : '${visits.length}',
                    onTap: onOpenAppointments,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Inbox',
                    badge: unread > 0 ? '$unread' : null,
                    onTap: onOpenMessages,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.folder_open_outlined,
                    label: 'Records',
                    onTap: onOpenRecords,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.favorite_border_rounded,
                    label: 'Care',
                    onTap: onOpenCare,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.payments_outlined,
                    label: 'Billing',
                    onTap: onOpenBilling,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.assignment_outlined,
                    label: 'Intake',
                    onTap: onOpenIntake,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.shield_outlined,
                    label: 'Privacy',
                    onTap: onOpenPrivacy,
                  ),
                  const SizedBox(width: 8),
                  ShortcutChip(
                    icon: Icons.apps_rounded,
                    label: 'All',
                    onTap: onOpenMore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting(String first) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$part, $first';
  }
}
