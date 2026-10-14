import 'api_client.dart';

class CareRepository {
  CareRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> show() {
    return client.get('/care');
  }

  Future<void> refill(String medicationName) async {
    await client.post('/care/refill', {'medication_name': medicationName}, auth: true);
  }

  Future<void> taken(String medicationName) async {
    await client.post('/care/adherence', {
      'medication_name': medicationName,
      'status': 'taken',
    }, auth: true);
  }
}
