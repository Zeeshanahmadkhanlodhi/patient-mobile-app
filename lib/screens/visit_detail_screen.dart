import 'package:flutter/material.dart';

import '../api/appointments_repository.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({
    super.key,
    required this.appointments,
    required this.visit,
  });

  final AppointmentsRepository appointments;
  final Map<String, dynamic> visit;

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late Map<String, dynamic> visit;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    visit = Map<String, dynamic>.from(widget.visit);
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    await AppHaptics.action();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      await AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = visit['id'];
    final provider = visit['provider_name']?.toString() ?? 'Care team';
    final facility = visit['facility_name']?.toString() ?? 'Clinic';
    final reason = visit['reason']?.toString() ?? visit['type']?.toString() ?? 'Appointment';
    final checkedIn = visit['checked_in'] == true;
    final status = visit['status']?.toString() ?? (checkedIn ? 'checked_in' : 'scheduled');
    final canCheckIn = canCheckInVisit(visit);
    final appointmentId = id is int ? id : int.tryParse(id?.toString() ?? '');

    return FeatureShell(
      title: 'Visit details',
      subtitle: formatVisitWhen(visit['starts_at']?.toString()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: const TextStyle(color: AppColors.danger)),
            ),
          DashboardCard(
            color: AppColors.teal,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    StatusPill(
                      label: status.replaceAll('_', ' '),
                      tone: checkedIn ? PillTone.success : PillTone.info,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatVisitWhen(visit['starts_at']?.toString()),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  facility,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('About this visit'),
          const SizedBox(height: 8),
          DashboardCard(
            child: Column(
              children: [
                InfoRow(icon: Icons.event_note_outlined, label: 'Reason', value: reason),
                InfoRow(icon: Icons.person_outline_rounded, label: 'Provider', value: provider),
                InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: facility),
                if (visit['duration_minutes'] != null)
                  InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Duration',
                    value: '${visit['duration_minutes']} minutes',
                  ),
                if ((visit['instructions']?.toString() ?? '').isNotEmpty)
                  InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Instructions',
                    value: visit['instructions'].toString(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (canCheckIn && appointmentId != null)
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => _run(
                        () => widget.appointments.checkIn(appointmentId),
                        'You are checked in.',
                      ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(busy ? 'Working…' : 'Check in'),
            ),
          if (canCheckIn && appointmentId != null) const SizedBox(height: 10),
          if (appointmentId != null && !checkedIn)
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel visit?'),
                          content: const Text('This will cancel your upcoming appointment with the clinic.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel visit')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _run(
                          () => widget.appointments.cancel(appointmentId),
                          'Visit cancelled.',
                        );
                      }
                    },
              icon: const Icon(Icons.event_busy_rounded, size: 18),
              label: const Text('Cancel appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          if (checkedIn) ...[
            const SizedBox(height: 8),
            DashboardCard(
              elevated: false,
              color: AppColors.tealMist,
              child: const Text(
                'You’re checked in. Please wait for your care team — they can see you’re ready.',
                style: TextStyle(color: AppColors.tealDeep, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
