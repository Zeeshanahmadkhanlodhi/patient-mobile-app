import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import 'select_clinic_screen.dart';

class ClinicDetailScreen extends StatefulWidget {
  const ClinicDetailScreen({
    super.key,
    required this.auth,
    required this.clinic,
    this.isPreferred = false,
  });

  final AuthRepository auth;
  final Map<String, dynamic> clinic;
  final bool isPreferred;

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  bool busy = false;
  String? error;

  Future<void> _prefer() async {
    final id = widget.clinic['id']?.toString();
    if (id == null) return;
    await AppHaptics.action();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.setPreferredClinic(id);
      await AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferred clinic updated.'), behavior: SnackBarBehavior.floating),
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
    final clinic = widget.clinic;
    final name = clinic['name']?.toString() ?? 'Clinic';
    final address = [
      clinic['street'] ?? clinic['address'] ?? clinic['address_line'],
      clinic['city'],
      clinic['state'],
      clinic['postal_code'] ?? clinic['zip'],
    ].where((p) => (p?.toString() ?? '').trim().isNotEmpty).map((e) => e.toString()).join(', ');
    final phone = clinic['phone']?.toString() ?? clinic['phone_number']?.toString() ?? '';
    final hours = clinic['hours']?.toString() ?? clinic['business_hours']?.toString() ?? '';
    final reason = clinic['reason']?.toString() ?? '';
    final distance = clinic['distance_km'] ?? clinic['distance_miles'] ?? clinic['distance'];

    return FeatureShell(
      title: 'Clinic',
      subtitle: widget.isPreferred ? 'Your preferred location' : 'Clinic details',
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.tealMist,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: AppColors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      if (clinic['is_nearest'] == true || reason.isNotEmpty)
                        StatusPill(
                          label: clinic['is_nearest'] == true ? 'Nearest' : reason,
                          tone: PillTone.success,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Details'),
          const SizedBox(height: 8),
          DashboardCard(
            child: Column(
              children: [
                if (address.isNotEmpty)
                  InfoRow(icon: Icons.place_outlined, label: 'Address', value: address)
                else
                  const InfoRow(icon: Icons.place_outlined, label: 'Address', value: 'Ask the front desk for directions'),
                if (phone.isNotEmpty) InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                if (hours.isNotEmpty) InfoRow(icon: Icons.schedule_outlined, label: 'Hours', value: hours),
                if (distance != null)
                  InfoRow(
                    icon: Icons.near_me_outlined,
                    label: 'Distance',
                    value: '$distance',
                  ),
                if ((clinic['specialty']?.toString() ?? '').isNotEmpty)
                  InfoRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Specialty',
                    value: clinic['specialty'].toString(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!widget.isPreferred)
            FilledButton(
              onPressed: busy ? null : _prefer,
              child: Text(busy ? 'Saving…' : 'Make preferred clinic'),
            )
          else ...[
            DashboardCard(
              elevated: false,
              color: AppColors.tealMist,
              child: const Text(
                'This is your preferred clinic for booking and messaging.',
                style: TextStyle(color: AppColors.tealDeep, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                final changed = await AppPageRoute.push<bool>(
                  context,
                  SelectClinicScreen(auth: widget.auth),
                );
                if (changed == true && context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Switch clinic'),
            ),
          ],
        ],
      ),
    );
  }
}
