import 'package:flutter/material.dart';

import '../api/records_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import '../api/care_repository.dart';
import 'documents_screen.dart';
import 'medications_screen.dart';
import 'results_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.records});

  final RecordsRepository records;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  Map<String, dynamic>? chart;
  String? error;
  String vitalKind = 'bp';
  final systolic = TextEditingController();
  final diastolic = TextEditingController();
  final value = TextEditingController();
  bool saving = false;
  bool loading = true;

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

  @override
  void dispose() {
    systolic.dispose();
    diastolic.dispose();
    value.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _list(String key) => [
        for (final row in ((chart?[key] as List?) ?? const []))
          if (row is Map) Map<String, dynamic>.from(row),
      ];

  Future<void> _logVital() async {
    await AppHaptics.action();
    setState(() => saving = true);
    try {
      await widget.records.logVital(
        kind: vitalKind,
        systolic: vitalKind == 'bp' ? int.tryParse(systolic.text) : null,
        diastolic: vitalKind == 'bp' ? int.tryParse(diastolic.text) : null,
        value: vitalKind == 'bp' ? null : num.tryParse(value.text),
      );
      systolic.clear();
      diastolic.clear();
      value.clear();
      await AppHaptics.success();
      await _load();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final encounters = _list('encounters');
    final allergies = _list('allergies');
    final problems = _list('problems');
    final held = _list('held_results');
    final vitals = _list('vitals');
    final series = _list('vital_series');

    return FeatureShell(
      title: 'Medical records',
      subtitle: 'Chart shared by your clinic',
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
                  if (chart?['linked'] != true)
                    DashboardCard(
                      elevated: false,
                      color: const Color(0xFFFFF6E8),
                      child: Text(
                        chart?['reason']?.toString() ?? 'No clinic record is linked yet.',
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (held.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DashboardCard(
                      elevated: false,
                      child: Text(
                        '${held.length} held result${held.length == 1 ? '' : 's'} waiting on clinic release.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const SectionLabel('Browse'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BrowseChip(
                          icon: Icons.science_outlined,
                          label: 'Results',
                          onTap: () => AppPageRoute.push(context, ResultsScreen(records: widget.records)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BrowseChip(
                          icon: Icons.medication_outlined,
                          label: 'Meds',
                          onTap: () => AppPageRoute.push(
                            context,
                            MedicationsScreen(care: CareRepository(widget.records.client)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BrowseChip(
                          icon: Icons.folder_outlined,
                          label: 'Docs',
                          onTap: () => AppPageRoute.push(context, DocumentsScreen(records: widget.records)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionLabel('Recent visits', trailing: Text('${encounters.length}', style: const TextStyle(color: AppColors.muted, fontSize: 12))),
                  const SizedBox(height: 8),
                  if (encounters.isEmpty)
                    const DashboardCard(elevated: false, child: Text('No visits listed yet.', style: TextStyle(color: AppColors.muted)))
                  else
                    ...encounters.take(6).map((row) {
                      final bits = <String>[
                        if ((row['provider_name'] as String?)?.isNotEmpty == true) row['provider_name'] as String,
                        if (row['conversation'] != null) 'Conversation',
                        if (row['scribe'] != null) 'AI scribe',
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DashboardCard(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: AppColors.tealMist, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.event_note_outlined, color: AppColors.teal, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['reason']?.toString() ?? 'Clinic visit',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink),
                                    ),
                                    if (bits.isNotEmpty)
                                      Text(bits.join(' · '), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  const SectionLabel('Allergies & problems'),
                  const SizedBox(height: 8),
                  DashboardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allergies', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.muted)),
                        const SizedBox(height: 6),
                        if (allergies.isEmpty)
                          const Text('None listed.', style: TextStyle(color: AppColors.ink))
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: allergies
                                .map((a) => StatusPill(label: a['name']?.toString() ?? 'Allergy', tone: PillTone.warning))
                                .toList(),
                          ),
                        const SizedBox(height: 14),
                        Text('Problems', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.muted)),
                        const SizedBox(height: 6),
                        if (problems.isEmpty)
                          const Text('None listed.', style: TextStyle(color: AppColors.ink))
                        else
                          ...problems.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${p['name'] ?? ''}', style: const TextStyle(color: AppColors.ink, fontSize: 14)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Log a home reading'),
                  const SizedBox(height: 8),
                  DashboardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(label: const Text('Blood pressure'), selected: vitalKind == 'bp', onSelected: (_) => setState(() => vitalKind = 'bp')),
                            ChoiceChip(label: const Text('Heart rate'), selected: vitalKind == 'hr', onSelected: (_) => setState(() => vitalKind = 'hr')),
                            ChoiceChip(label: const Text('Weight'), selected: vitalKind == 'weight', onSelected: (_) => setState(() => vitalKind = 'weight')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (vitalKind == 'bp') ...[
                          TextField(controller: systolic, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Systolic')),
                          TextField(controller: diastolic, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diastolic')),
                        ] else
                          TextField(
                            controller: value,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: vitalKind == 'hr' ? 'Beats per minute' : 'Pounds'),
                          ),
                        const SizedBox(height: 10),
                        FilledButton(onPressed: saving ? null : _logVital, child: Text(saving ? 'Saving…' : 'Save home reading')),
                      ],
                    ),
                  ),
                  if (series.isNotEmpty || vitals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Vitals'),
                    const SizedBox(height: 8),
                    ...series.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DashboardCard(
                            elevated: false,
                            child: Text(
                              '${s['title'] ?? ''} · latest ${s['latest'] ?? ''} ${s['unit'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )),
                    ...vitals.take(8).map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: DashboardCard(
                            elevated: false,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Text(
                              '${v['name'] ?? ''} · ${v['value'] ?? ''}${v['source'] == 'patient' ? ' · home' : ''}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
      ),
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink)),
        ],
      ),
    );
  }
}
