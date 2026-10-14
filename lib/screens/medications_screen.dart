import 'package:flutter/material.dart';

import '../api/care_repository.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key, required this.care});

  final CareRepository care;

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = data == null;
      error = null;
    });
    try {
      final next = await widget.care.show();
      if (!mounted) return;
      setState(() {
        data = next;
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

  Future<void> _taken(String name) async {
    await AppHaptics.action();
    setState(() => busy = true);
    try {
      await widget.care.taken(name);
      await AppHaptics.success();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $name as taken'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _refill(String name) async {
    await AppHaptics.action();
    setState(() => busy = true);
    try {
      await widget.care.refill(name);
      await AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill request sent to your clinic'), behavior: SnackBarBehavior.floating),
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
    final chart = data?['chart'] as Map<String, dynamic>?;
    final meds = <Map<String, dynamic>>[
      for (final row in ((chart?['medications'] as List?) ?? const []))
        if (row is Map) Map<String, dynamic>.from(row),
    ];

    return FeatureShell(
      title: 'Medications',
      subtitle: 'Track doses & request refills',
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : error != null && meds.isEmpty
                ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(error!, style: const TextStyle(color: AppColors.danger)))])
                : meds.isEmpty
                    ? ListView(
                        children: const [
                          EmptyState(
                            icon: Icons.medication_outlined,
                            title: 'No medications on file',
                            detail: 'When your clinic adds prescriptions, they will appear here for taken logs and refills.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                        itemCount: meds.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final med = meds[index];
                          final name = med['name']?.toString() ?? 'Medication';
                          final status = med['status']?.toString() ?? 'Active';
                          final sig = med['sig']?.toString() ?? med['instructions']?.toString() ?? '';
                          return DashboardCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                                    ),
                                    StatusPill(label: status, tone: PillTone.info),
                                  ],
                                ),
                                if (sig.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(sig, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: busy ? null : () => _taken(name),
                                        child: const Text('Taken'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: busy ? null : () => _refill(name),
                                        child: const Text('Request refill'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
