import 'package:flutter/material.dart';

import '../api/privacy_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

const labels = {
  'share_clinical_notes': 'Share patient-visible notes',
  'share_results': 'Share results after the clinic delay',
  'share_billing': 'Share statements and balances',
  'npp': 'Notice of Privacy Practices',
  'research': 'Allow research contact',
  'marketing': 'Allow clinic marketing messages',
};

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, required this.privacy});

  final PrivacyRepository privacy;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, dynamic>? data;
  final grants = <String, bool>{};
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final payload = await widget.privacy.show();
      final consents = (payload['consents'] as List<dynamic>?) ?? [];
      grants
        ..clear()
        ..addEntries(consents.map((row) {
          final item = row as Map<String, dynamic>;
          return MapEntry(item['type'] as String, item['granted'] == true);
        }));
      setState(() {
        data = payload;
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      await widget.privacy.saveConsents({
        'share_clinical_notes': grants['share_clinical_notes'] ?? false,
        'share_results': grants['share_results'] ?? false,
        'share_billing': grants['share_billing'] ?? false,
        'npp': grants['npp'] ?? false,
        'research': grants['research'] ?? false,
        'marketing': grants['marketing'] ?? false,
      });
      await _load();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = (data?['access'] as List<dynamic>?) ?? [];
    final disclosures = (data?['disclosures'] as List<dynamic>?) ?? [];
    final ageOut = data?['age_out'] as Map<String, dynamic>?;

    return FeatureShell(
      title: 'Privacy',
      subtitle: 'Consents & access log',
      child: error != null && data == null
          ? Center(child: Text(error!, style: const TextStyle(color: AppColors.danger)))
          : data == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  children: [
                    if (ageOut?['needs_reconsent'] == true) ...[
                      DashboardCard(
                        elevated: false,
                        color: const Color(0xFFFFF6E8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You are 18 or older. Confirm this adult account to keep using the portal.',
                              style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      setState(() => busy = true);
                                      try {
                                        await widget.privacy.adultReconsent();
                                        await _load();
                                      } catch (e) {
                                        setState(() => error = e.toString());
                                      } finally {
                                        if (mounted) setState(() => busy = false);
                                      }
                                    },
                              child: const Text('Confirm adult account'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SectionLabel('Consents'),
                    const SizedBox(height: 8),
                    DashboardCard(
                      child: Column(
                        children: [
                          ...labels.entries.map((entry) => SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                value: grants[entry.key] ?? false,
                                activeThumbColor: AppColors.teal,
                                onChanged: (value) => setState(() => grants[entry.key] = value),
                              )),
                          FilledButton(onPressed: busy ? null : _save, child: const Text('Save privacy choices')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Record releases'),
                    const SizedBox(height: 8),
                    if (disclosures.isEmpty)
                      const DashboardCard(elevated: false, child: Text('None yet.', style: TextStyle(color: AppColors.muted)))
                    else
                      ...disclosures.map((row) {
                        final item = row as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DashboardCard(
                            elevated: false,
                            child: Text(
                              '${item['recipient_name'] ?? ''} · ${item['kind']} · ${item['status']}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    const SectionLabel('Who opened your record'),
                    const SizedBox(height: 8),
                    if (access.isEmpty)
                      const DashboardCard(elevated: false, child: Text('No access events yet.', style: TextStyle(color: AppColors.muted)))
                    else
                      ...access.map((row) {
                        final item = row as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DashboardCard(
                            elevated: false,
                            child: Text(
                              '${item['action'] ?? ''} · ${item['who'] ?? ''} · ${item['when'] ?? ''}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
