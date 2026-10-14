import 'api_client.dart';

class MessagesRepository {
  MessagesRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> inbox() => client.get('/messages');

  Future<List<dynamic>> list() async {
    final data = await inbox();
    return (data['threads'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> show(int id) {
    return client.get('/messages/$id');
  }

  Future<Map<String, dynamic>> start({
    required String queue,
    required String subject,
    required String body,
  }) {
    return client.post('/messages', {
      'queue': queue,
      'subject': subject,
      'body': body,
    }, auth: true);
  }

  Future<Map<String, dynamic>> reply(int id, String body) {
    return client.post('/messages/$id', {'body': body}, auth: true);
  }
}
