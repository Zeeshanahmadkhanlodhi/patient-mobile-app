import 'api_client.dart';

class BillingRepository {
  BillingRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> show() => client.get('/billing');

  Future<Map<String, dynamic>> estimate({
    required int serviceId,
    required bool useInsurance,
    int copayCents = 0,
    int deductibleCents = 0,
    int coinsurancePercent = 20,
  }) async {
    final data = await client.post('/billing/estimate', {
      'service_id': serviceId,
      'use_insurance': useInsurance,
      'copay_cents': copayCents,
      'deductible_remaining_cents': deductibleCents,
      'coinsurance_percent': coinsurancePercent,
    }, auth: true);
    return (data['estimate'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> startPlan(int statementId, int months) async {
    await client.post('/billing/plans', {
      'statement_id': statementId,
      'months': months,
    }, auth: true);
  }

  Future<void> payInstallment(int planId, int installmentId) async {
    await client.post('/billing/plans/$planId/installments/$installmentId/pay', {}, auth: true);
  }

  Future<void> payBalance() async {
    await client.post('/billing/pay', {}, auth: true);
  }
}
