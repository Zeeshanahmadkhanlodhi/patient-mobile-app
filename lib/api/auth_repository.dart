import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthRepository {
  AuthRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await client.post('/auth/login', {
      'email': email,
      'password': password,
      'device_name': 'flutter',
    });
    await _persist(data);
    return data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final data = await client.post('/auth/register', payload);
    await _persist(data);
    return data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return client.post('/auth/forgot-password', {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) {
    return client.post('/auth/reset-password', {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<Map<String, dynamic>> me() => client.get('/me');

  Future<Map<String, dynamic>> clinics() => client.get('/me/clinics');

  Future<Map<String, dynamic>> useNearestClinic() =>
      client.post('/me/preferred-clinic', {}, auth: true);

  Future<Map<String, dynamic>> setPreferredClinic(String facilityId) =>
      client.post('/me/preferred-clinic', {
        'facility_id': facilityId,
      }, auth: true);

  Future<Map<String, dynamic>> switchProxy(int identityId) =>
      client.post('/me/proxy', {
        'identity_id': identityId,
      }, auth: true);

  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> logout() async {
    try {
      await client.post('/auth/logout', {}, auth: true);
    } finally {
      await clearSession();
    }
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token'] as String);
  }
}
