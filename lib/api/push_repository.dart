import 'dart:io';

import 'api_client.dart';

class PushRepository {
  PushRepository(this.client);

  final ApiClient client;

  Future<void> register(String token, {String? platform, String? appVersion}) {
    return client.post('/devices/push-token', {
      'token': token,
      'platform': platform ?? _platform(),
      'app_version': ?appVersion,
    }, auth: true);
  }

  Future<void> unregister(String token) {
    return client.delete('/devices/push-token', {
      'token': token,
    }, auth: true);
  }

  String _platform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
