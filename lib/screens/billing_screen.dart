import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/billing_repository.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, required this.billing});

  final BillingRepository billing;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Map<String, dynamic>? data;
  Map<String, dynamic>? estimate;
  String? error;
  bool busy = false;
  bool loading = true;
  int? serviceId;
  bool useInsurance = false;
  final copay = TextEditingController(text: '25');
  final deductible = TextEditingController(text: '0');
  final coinsurance = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    copay.dispose();
    deductible.dispose();
    coinsurance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = data == null;
      error = null;
    });
    try {
      final payload = await widget.billing.show();
      final services = (payload['services'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        data = payload;
        serviceId ??= services.isNotEmpty ? (services.first as Map<String, dynamic>)['id'] as int? : null;
        useInsurance = (payload['insurance'] as Map<String, dynamic>?)?['payer_name'] != null;
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

  Future<void> _run(Future<void> Function() action) async {
    await AppHaptics.action();
    setState(() => busy = true);
    try {
      await action();
      await AppHaptics.success();
      await _load();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _money(num? cents) => ((cents ?? 0) / 100).toStringAsFixed(2);

  Future<void> _openPay(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => error = 'This payment link is not valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => error = 'Could not open the payment page.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = data?['due_cents'] as num? ?? 0;
    final statements = (data?['statements'] as List<dynamic>?) ?? [];
    final services = (data?['services'] as List<dynamic>?) ?? [];
    final plans = (data?['plans'] as List<dynamic>?) ?? [];
    final months = (data?['plan_months'] as List<dynamic>?) ?? [3, 6];
    final clinicPayments = (data?['instamed_requests'] as List<dynamic>?) ?? [];

    return FeatureShell(
      title: 'Billing',
      subtitle: 'Balance, estimates & plans',
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : error != null && data == null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(error!, style: const TextStyle(color: AppColors.danger)))])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    children: [
                      if (data?['can_see_billing'] == false)
                        const DashboardCard(
                          elevated: false,
                          color: Color(0xFFFFF6E8),
                          child: Text(
                            'Turn on billing sharing in Privacy to keep statements on this page.',
                            style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                          ),
                        ),
                      DashboardCard(
                        color: AppColors.teal,
                        borderColor: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount due',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${data?['balance'] ?? '0.00'}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                            ),
                            if (due > 0) ...[
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: busy ? null : () => _run(widget.billing.payBalance),
                                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.tealDeep),
                                child: const Text('Pay this balance'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (clinicPayments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const SectionLabel('From the front desk'),
                        const SizedBox(height: 8),
                        ...clinicPayments.map((row) {
                          final request = row as Map<String, dynamic>;
                          final status = request['status']?.toString() ?? '';
                          final payUrl = request['pay_url']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DashboardCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${request['amount'] ?? '0.00'} · $status',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  if ((request['description']?.toString() ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        request['description'].toString(),
                                        style: const TextStyle(color: AppColors.muted),
                                      ),
                                    ),
                                  if (status == 'pending' && payUrl.isNotEmpty)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton(
                                        onPressed: busy ? null : () => _openPay(payUrl),
                                        child: const Text('Pay with InstaMed'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      const SectionLabel('Cost estimate'),
                      const SizedBox(height: 8),
                      DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: services.map((row) {
                                final service = row as Map<String, dynamic>;
                                final id = service['id'] as int;
                                return ChoiceChip(
                                  label: Text(service['name']?.toString() ?? ''),
                                  selected: id == serviceId,
                                  onSelected: (_) => setState(() => serviceId = id),
                                );
                              }).toList(),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Use insurance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              value: useInsurance,
                              activeThumbColor: AppColors.teal,
                              onChanged: (value) => setState(() => useInsurance = value),
                            ),
                            if (useInsurance) ...[
                              TextField(controller: copay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Copay \$')),
                              TextField(controller: deductible, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Deductible left \$')),
                              TextField(controller: coinsurance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Coinsurance %')),
                            ],
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: busy || serviceId == null
                                  ? null
                                  : () async {
                                      setState(() => busy = true);
                                      try {
                                        final quote = await widget.billing.estimate(
                                          serviceId: serviceId!,
                                          useInsurance: useInsurance,
                                          copayCents: ((double.tryParse(copay.text) ?? 0) * 100).round(),
                                          deductibleCents: ((double.tryParse(deductible.text) ?? 0) * 100).round(),
                                          coinsurancePercent: int.tryParse(coinsurance.text) ?? 20,
                                        );
                                        setState(() => estimate = quote);
                                      } catch (e) {
                                        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
                                      } finally {
                                        if (mounted) setState(() => busy = false);
                                      }
                                    },
                              child: const Text('Estimate my share'),
                            ),
                            if (estimate != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'You may owe \$${_money(estimate!['patient_cents'] as num?)}. ${estimate!['disclaimer'] ?? ''}',
                                style: const TextStyle(color: AppColors.muted, height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SectionLabel('Payment plans'),
                      const SizedBox(height: 8),
                      if (plans.isEmpty)
                        const DashboardCard(elevated: false, child: Text('No active plan.', style: TextStyle(color: AppColors.muted)))
                      else
                        ...plans.map((row) {
                          final plan = row as Map<String, dynamic>;
                          final installments = (plan['installments'] as List<dynamic>?) ?? [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DashboardCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${plan['installment_count']} months · \$${plan['remaining']} left · ${plan['status']}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  ...installments.map((item) {
                                    final installment = item as Map<String, dynamic>;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('${installment['sequence']} · \$${installment['amount']} · ${installment['status']}'),
                                      trailing: installment['can_pay'] == true
                                          ? TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _run(() => widget.billing.payInstallment(plan['id'] as int, installment['id'] as int)),
                                              child: const Text('Pay'),
                                            )
                                          : null,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      const SectionLabel('Statements'),
                      const SizedBox(height: 8),
                      ...statements.map((row) {
                        final statement = row as Map<String, dynamic>;
                        final status = statement['status']?.toString() ?? '';
                        final balanceCents = statement['balance_cents'] as num? ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DashboardCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${statement['number']} · $status', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text('Balance \$${_money(balanceCents)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (status == 'due' && balanceCents > 0)
                                  PopupMenuButton<int>(
                                    onSelected: (value) => _run(() => widget.billing.startPlan(statement['id'] as int, value)),
                                    itemBuilder: (_) => months
                                        .map((month) => PopupMenuItem(value: month as int, child: Text('$month-month plan')))
                                        .toList(),
                                    child: const StatusPill(label: 'Plan', tone: PillTone.info),
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
