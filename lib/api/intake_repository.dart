import 'api_client.dart';

class IntakeRepository {
  IntakeRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> show() => client.get('/intake');

  Future<Map<String, dynamic>> submit(List<int> answers) async {
    final data = await client.post('/intake', {
      'answers': answers,
      'npp_ack': true,
    }, auth: true);
    return (data['latest'] as Map<String, dynamic>?) ?? {};
  }
}
