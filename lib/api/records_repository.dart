import 'api_client.dart';

class RecordsRepository {
  RecordsRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> chart() async {
    final data = await client.get('/records');
    return (data['chart'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> encounter(String encounterId) {
    return client.get('/records/encounters/$encounterId');
  }

  Future<Map<String, dynamic>> disclosures() {
    return client.get('/records/disclosures');
  }

  Future<void> logVital({
    required String kind,
    int? systolic,
    int? diastolic,
    num? value,
  }) async {
    await client.post('/records/vitals', {
      'kind': kind,
      if (systolic case final systolic?) 'systolic': systolic,
      if (diastolic case final diastolic?) 'diastolic': diastolic,
      if (value case final value?) 'value': value,
    }, auth: true);
  }
}
