import 'package:flutter/material.dart';

import '../api/records_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.records});

  final RecordsRepository records;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
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
    final notes = _maps('notes');
    final immunizations = _maps('immunizations');
    final devices = _maps('devices');

    return FeatureShell(
      title: 'Documents',
      subtitle: 'Notes & clinical files',
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
                  _block(
                    'Clinical notes',
                    notes,
                    empty: 'No shared notes yet.',
                    titleOf: (r) => r['title']?.toString() ?? 'Note',
                    detailOf: (r) => r['summary']?.toString() ?? r['date']?.toString() ?? '',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  _block(
                    'Immunizations',
                    immunizations,
                    empty: 'No immunizations on file.',
                    titleOf: (r) => r['name']?.toString() ?? 'Immunization',
                    detailOf: (r) => r['date']?.toString() ?? r['administered_at']?.toString() ?? '',
                    icon: Icons.vaccines_outlined,
                  ),
                  const SizedBox(height: 14),
                  _block(
                    'Devices',
                    devices,
                    empty: 'No devices listed.',
                    titleOf: (r) => r['name']?.toString() ?? 'Device',
                    detailOf: (r) => r['manufacturer']?.toString() ?? '',
                    icon: Icons.watch_outlined,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _block(
    String label,
    List<Map<String, dynamic>> rows, {
    required String empty,
    required String Function(Map<String, dynamic>) titleOf,
    required String Function(Map<String, dynamic>) detailOf,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          DashboardCard(
            elevated: false,
            child: Text(empty, style: const TextStyle(color: AppColors.muted)),
          )
        else
          ...rows.map((row) {
            final detail = detailOf(row);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DashboardCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.tealMist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleOf(row), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                          if (detail.isNotEmpty)
                            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
