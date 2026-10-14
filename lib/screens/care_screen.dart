import 'package:flutter/material.dart';

import '../api/care_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import 'medications_screen.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key, required this.care});

  final CareRepository care;

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;

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

  @override
  Widget build(BuildContext context) {
    final chart = data?['chart'] as Map<String, dynamic>?;
    final meds = <Map<String, dynamic>>[
      for (final row in ((chart?['medications'] as List?) ?? const []))
        if (row is Map) Map<String, dynamic>.from(row),
    ];
    final education = <Map<String, dynamic>>[
      for (final row in ((data?['education'] as List?) ?? const []))
        if (row is Map) Map<String, dynamic>.from(row),
    ];

    return FeatureShell(
      title: 'Care plan',
      subtitle: 'Meds, refills & education',
      actions: [
        TextButton(
          onPressed: () => AppPageRoute.push(context, MedicationsScreen(care: widget.care)),
          child: const Text('All meds'),
        ),
      ],
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  const SectionLabel('Medications'),
                  const SizedBox(height: 8),
                  if (meds.isEmpty)
                    const DashboardCard(
                      elevated: false,
                      child: Text('No medications on file.', style: TextStyle(color: AppColors.muted)),
                    )
                  else
                    ...meds.take(5).map((med) {
                      final name = med['name']?.toString() ?? 'Medication';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DashboardCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                                  ),
                                  StatusPill(label: med['status']?.toString() ?? 'Active', tone: PillTone.info),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await AppHaptics.action();
                                        await widget.care.taken(name);
                                        await _load();
                                      },
                                      child: const Text('Taken'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () async {
                                        await AppHaptics.action();
                                        await widget.care.refill(name);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Refill sent to the clinic'), behavior: SnackBarBehavior.floating),
                                        );
                                      },
                                      child: const Text('Refill'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  const SectionLabel('Education'),
                  const SizedBox(height: 8),
                  if (education.isEmpty)
                    const DashboardCard(
                      elevated: false,
                      child: Text('No education articles yet.', style: TextStyle(color: AppColors.muted)),
                    )
                  else
                    ...education.map((article) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DashboardCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article['title']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article['summary']?.toString() ?? '',
                                style: const TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
