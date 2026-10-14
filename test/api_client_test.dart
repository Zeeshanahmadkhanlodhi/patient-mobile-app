import 'package:flutter_test/flutter_test.dart';
import 'package:patient_portal/api/api_client.dart';

void main() {
  test('normalizes a laptop address into the API root', () {
    expect(
      ApiClient.normalizeBaseUrl('192.168.1.20:8010'),
      'http://192.168.1.20:8010/api/v1',
    );
    expect(
      ApiClient.normalizeBaseUrl('http://10.0.2.2:8010/'),
      'http://10.0.2.2:8010/api/v1',
    );
    expect(
      ApiClient.normalizeBaseUrl('http://127.0.0.1:8010/api/v1'),
      'http://127.0.0.1:8010/api/v1',
    );
  });

  test('falls back to the demo clinic slug', () {
    expect(ApiClient.normalizeTenantSlug('  Riverside '), 'riverside');
    expect(ApiClient.normalizeTenantSlug(''), ApiClient.defaultTenantSlug);
  });
}
