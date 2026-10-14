import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Single Laravel API contract shared with the Inertia web client.
class ApiClient {
  ApiClient({this.baseUrlOverride, this.tenantSlugOverride});

  static const defaultBaseUrl = 'http://127.0.0.1:8010/api/v1';
  static const defaultTenantSlug = 'riverside';
  static const baseUrlKey = 'api_base_url';
  static const tenantSlugKey = 'tenant_slug';

  final String? baseUrlOverride;
  final String? tenantSlugOverride;

  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) {
      return defaultBaseUrl;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    url = url.replaceFirst(RegExp(r'/+$'), '');
    if (!url.contains('/api')) {
      url = '$url/api/v1';
    }
    return url;
  }

  static String normalizeTenantSlug(String raw) {
    final slug = raw.trim().toLowerCase();
    return slug.isEmpty ? defaultTenantSlug : slug;
  }

  Future<String> baseUrl() async {
    if (baseUrlOverride != null) {
      return normalizeBaseUrl(baseUrlOverride!);
    }
    final prefs = await SharedPreferences.getInstance();
    return normalizeBaseUrl(prefs.getString(baseUrlKey) ?? defaultBaseUrl);
  }

  Future<String> tenantSlug() async {
    if (tenantSlugOverride != null) {
      return normalizeTenantSlug(tenantSlugOverride!);
    }
    final prefs = await SharedPreferences.getInstance();
    return normalizeTenantSlug(prefs.getString(tenantSlugKey) ?? defaultTenantSlug);
  }

  Future<void> saveEndpoint({required String baseUrl, required String tenantSlug}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(baseUrlKey, normalizeBaseUrl(baseUrl));
    await prefs.setString(tenantSlugKey, normalizeTenantSlug(tenantSlug));
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Tenant': await tenantSlug(),
    };

    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${await baseUrl()}$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _decode(response);
    } on http.ClientException catch (e) {
      throw Exception(_connectionMessage(e));
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${await baseUrl()}$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _decode(response);
    } on http.ClientException catch (e) {
      throw Exception(_connectionMessage(e));
    }
  }

  Future<Map<String, dynamic>> delete(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${await baseUrl()}$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _decode(response);
    } on http.ClientException catch (e) {
      throw Exception(_connectionMessage(e));
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('${await baseUrl()}$path'),
        headers: await _headers(auth: true),
      );
      return _decode(response);
    } on http.ClientException catch (e) {
      throw Exception(_connectionMessage(e));
    }
  }

  String _connectionMessage(http.ClientException error) {
    final detail = error.message.toLowerCase();
    if (detail.contains('connection refused') ||
        detail.contains('failed host lookup') ||
        detail.contains('network is unreachable') ||
        detail.contains('timed out')) {
      return 'Cannot reach the clinic portal. Make sure it is running, then try again.';
    }
    return error.message;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response from portal API');
    }
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(decoded, response.statusCode));
    }
    return decoded;
  }

  String _errorMessage(Map<String, dynamic> decoded, int statusCode) {
    final message = decoded['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    final errors = decoded['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return 'Request failed ($statusCode)';
  }
}
