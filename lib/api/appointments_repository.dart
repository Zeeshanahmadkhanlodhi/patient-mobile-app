import 'api_client.dart';

class AppointmentsRepository {
  AppointmentsRepository(this.client);

  final ApiClient client;

  Future<List<dynamic>> list() async {
    final data = await client.get('/appointments');
    return (data['appointments'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> providers({String? facilityId}) async {
    final query = facilityId == null || facilityId.isEmpty
        ? ''
        : '?facility_id=${Uri.encodeQueryComponent(facilityId)}';
    final data = await client.get('/appointments/providers$query');
    return (data['providers'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> slots(String providerId, {String? facilityId}) async {
    final params = <String, String>{'provider_id': providerId};
    if (facilityId != null && facilityId.isNotEmpty) {
      params['facility_id'] = facilityId;
    }
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final data = await client.get('/appointments/slots?$query');
    return (data['slots'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> book(
    String providerId,
    String start, {
    String? facilityId,
    String? facilityName,
  }) {
    return client.post('/appointments', {
      'provider_id': providerId,
      'start': start,
      if (facilityId != null && facilityId.isNotEmpty) 'facility_id': facilityId,
      if (facilityName != null && facilityName.isNotEmpty) 'facility_name': facilityName,
    }, auth: true);
  }

  Future<void> cancel(int id) async {
    await client.post('/appointments/$id/cancel', {}, auth: true);
  }

  Future<void> checkIn(int id) async {
    await client.post('/appointments/$id/check-in', {}, auth: true);
  }
}
