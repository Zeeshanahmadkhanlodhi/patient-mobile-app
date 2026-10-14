import 'api_client.dart';

class PrivacyRepository {
  PrivacyRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> show() => client.get('/privacy');

  Future<void> saveConsents(Map<String, bool> grants) async {
    await client.put('/privacy/consents', grants);
  }

  Future<void> adultReconsent() async {
    await client.post('/privacy/adult-reconsent', {}, auth: true);
  }
}
