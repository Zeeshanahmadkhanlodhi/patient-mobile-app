import 'package:flutter/material.dart';

import '../api/records_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.records});

  final RecordsRepository records;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? chart;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = chart == null;
      error = null;
    });
    try {
      final data = await widget.records.chart();
      if (!mounted) return;
      setState(() {
        chart = data;
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

  List<Map<String, dynamic>> _maps(String key) => [
        for (final row in ((chart?[key] as List?) ?? const []))
          if (row is Map) Map<String, dynamic>.from(row),
      ];

  @override
  Widget build(BuildContext context) {
    final results = _maps('results');
    final held = _maps('held_results');

    return FeatureShell(
      title: 'Lab & results',
      subtitle: 'Released by your clinic',
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
                  if (held.isNotEmpty) ...[
                    DashboardCard(
                      elevated: false,
                      color: const Color(0xFFFFF6E8),
                      child: Text(
                        '${held.length} result${held.length == 1 ? '' : 's'} waiting on clinic release.',
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SectionLabel('Released results'),
                  const SizedBox(height: 8),
                  if (results.isEmpty)
                    const EmptyState(
                      icon: Icons.science_outlined,
                      title: 'No results yet',
                      detail: 'When your clinic releases labs or imaging, they will show up here.',
                    )
                  else
                    ...results.map((row) {
                      final title = row['title']?.toString() ?? 'Result';
                      final value = row['value']?.toString() ?? '';
                      final date = row['collected_at']?.toString() ?? row['date']?.toString() ?? '';
                      final flag = row['flag']?.toString() ?? row['status']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DashboardCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                                  ),
                                  if (flag.isNotEmpty)
                                    StatusPill(
                                      label: flag,
                                      tone: flag.toLowerCase().contains('abnormal') || flag.toLowerCase().contains('high')
                                          ? PillTone.warning
                                          : PillTone.neutral,
                                    ),
                                ],
                              ),
                              if (value.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.tealDeep)),
                              ],
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(date, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                              ],
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
