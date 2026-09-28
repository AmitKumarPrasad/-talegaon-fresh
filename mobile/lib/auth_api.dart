import 'dart:convert';

import 'package:http/http.dart' as http;

import 'main.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phone);
  Future<CustomerSession> verifyOtp(String phone, String otp);
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  Future<void> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<CustomerSession> verifyOtp(String phone, String otp) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (otp != '123456') {
      throw const AuthException('Invalid OTP. Use 123456 for the demo flow.');
    }
    return CustomerSession(
      phone: phone,
      name: 'Talegaon Customer',
      token: 'demo-token',
    );
  }
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment(
          'AUTH_BASE_URL',
          defaultValue: 'https://talegaon-fresh-ai-backend.onrender.com',
        )).replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<void> requestOtp(String phone) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/request-otp'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    _ensureSuccess(response, fallback: 'Unable to send OTP.');
  }

  @override
  Future<CustomerSession> verifyOtp(String phone, String otp) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    _ensureSuccess(response, fallback: 'Unable to verify OTP.');

    try {
      final body = jsonDecode(response.body);
      if (body is! Map) {
        throw const AuthException('Invalid authentication response.');
      }
      final token = body['token'];
      final name = body['name'];
      if (token is! String || token.isEmpty) {
        throw const AuthException('Authentication response did not include a token.');
      }
      return CustomerSession(
        phone: body['phone'] is String && (body['phone'] as String).isNotEmpty
            ? body['phone'] as String
            : phone,
        name: name is String && name.isNotEmpty ? name : 'Talegaon Customer',
        token: token,
      );
    } on FormatException {
      throw const AuthException('Authentication response was not valid JSON.');
    }
  }

  void _ensureSuccess(http.Response response, {required String fallback}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        throw AuthException(body['detail'] as String);
      }
      if (body is Map && body['message'] is String) {
        throw AuthException(body['message'] as String);
      }
    } on AuthException {
      rethrow;
    } on FormatException {
      // Fall through to the generic error below.
    }
    throw AuthException(fallback);
  }
}
