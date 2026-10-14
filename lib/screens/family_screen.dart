import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    required this.auth,
    this.me,
    required this.onChanged,
  });

  final AuthRepository auth;
  final Map<String, dynamic>? me;
  final Future<void> Function() onChanged;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  Map<String, dynamic>? me;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    me = widget.me;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await widget.auth.me();
      if (!mounted) return;
      setState(() {
        me = fresh;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _switchTo(int identityId, String label) async {
    await AppHaptics.action();
    setState(() => busy = true);
    try {
      await widget.auth.switchProxy(identityId);
      await AppHaptics.success();
      await widget.onChanged();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now managing $label'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = me?['user'] as Map<String, dynamic>?;
    final proxies = ((me?['proxies'] as List<dynamic>?) ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final name = user?['name']?.toString() ?? 'You';

    return FeatureShell(
      title: 'Family access',
      subtitle: 'People you can manage',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: const TextStyle(color: AppColors.danger)),
            ),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current profile', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text(
                  'Proxy access is granted by your clinic. Switch profiles to book visits or message on their behalf.',
                  style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Linked people'),
          const SizedBox(height: 8),
          if (proxies.isEmpty)
            const EmptyState(
              icon: Icons.family_restroom_rounded,
              title: 'No family proxies yet',
              detail: 'Ask your clinic to link a caregiver or dependent account if you manage care for someone else.',
            )
          else
            ...proxies.map((proxy) {
              final relationship = proxy['relationship']?.toString() ?? 'Proxy';
              final label = proxy['name']?.toString() ?? relationship;
              final id = (proxy['identity_id'] as num?)?.toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DashboardCard(
                  onTap: busy || id == null ? null : () => _switchTo(id, label),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.tealMist,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          initialsFor(label),
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                            Text(relationship, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const StatusPill(label: 'Switch', tone: PillTone.info),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
