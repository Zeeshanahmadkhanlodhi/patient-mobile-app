import 'package:flutter/material.dart';

import '../api/appointments_repository.dart';
import '../api/auth_repository.dart';
import '../api/messages_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import 'messages_screen.dart';
import 'visit_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notice> notices = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final me = await widget.auth.me();
      final appointments = AppointmentsRepository(widget.auth.client);
      final messages = MessagesRepository(widget.auth.client);
      final visits = await appointments.list();
      final inbox = await messages.inbox();
      final threads = <Map<String, dynamic>>[
        for (final row in ((inbox['threads'] as List<dynamic>?) ?? const []))
          if (row is Map) Map<String, dynamic>.from(row),
      ];

      final next = <_Notice>[];
      for (final row in visits) {
        if (row is! Map) continue;
        final visit = Map<String, dynamic>.from(row);
        next.add(
          _Notice(
            icon: Icons.calendar_month_rounded,
            title: 'Upcoming visit',
            detail: '${visit['provider_name'] ?? 'Care team'} · ${formatVisitWhen(visit['starts_at']?.toString())}',
            tone: PillTone.info,
            onTap: () => AppPageRoute.push(
              context,
              VisitDetailScreen(appointments: appointments, visit: visit),
            ),
          ),
        );
      }
      for (final thread in threads.where((t) => t['unread'] == true).take(8)) {
        next.add(
          _Notice(
            icon: Icons.mark_email_unread_rounded,
            title: thread['subject']?.toString() ?? 'Clinic message',
            detail: thread['preview']?.toString() ?? 'New message in your inbox',
            tone: PillTone.warning,
            onTap: () => AppPageRoute.push(
              context,
              MessagesScreen(messages: messages),
            ),
          ),
        );
      }

      final unread = (me['unread_messages'] as num?)?.toInt() ?? 0;
      if (next.isEmpty && unread == 0) {
        // keep empty
      }

      if (!mounted) return;
      setState(() {
        notices = next;
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

  @override
  Widget build(BuildContext context) {
    return FeatureShell(
      title: 'Notifications',
      subtitle: 'Visits & clinic messages',
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : error != null && notices.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(error!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  )
                : notices.isEmpty
                    ? ListView(
                        children: const [
                          EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'You’re all caught up',
                            detail: 'Visit reminders and unread clinic messages will show up here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                        itemCount: notices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notice = notices[index];
                          return DashboardCard(
                            onTap: notice.onTap,
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.tealMist,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(notice.icon, color: AppColors.teal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notice.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        notice.detail,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(label: notice.tone == PillTone.warning ? 'New' : 'Visit', tone: notice.tone),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _Notice {
  const _Notice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final PillTone tone;
  final VoidCallback onTap;
}
