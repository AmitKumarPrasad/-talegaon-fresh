import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talegaon_fresh/auth_api.dart';

void main() {
  test('demo auth repository preserves the current OTP flow', () async {
    const repository = DemoAuthRepository();
    await repository.requestOtp('9876543210');
    final session = await repository.verifyOtp('9876543210', '123456');

    expect(session.phone, '9876543210');
    expect(session.name, 'Talegaon Customer');
    expect(session.token, 'demo-token');
  });

  test('demo auth repository rejects an invalid OTP', () async {
    const repository = DemoAuthRepository();

    expect(
      () => repository.verifyOtp('9876543210', '000000'),
      throwsA(isA<AuthException>()),
    );
  });

  test('HTTP auth repository sends OTP request to configured endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://example.test/auth/request-otp');
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body), {'phone': '9876543210'});
      return http.Response('{}', 200);
    });

    final repository = HttpAuthRepository(
      client: client,
      baseUrl: 'https://example.test/',
    );

    await repository.requestOtp('9876543210');
  });

  test('HTTP auth repository maps verify response to a customer session', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.test/auth/verify-otp');
      expect(jsonDecode(request.body), {
        'phone': '9876543210',
        'otp': '654321',
      });
      return http.Response(
        jsonEncode({
          'token': 'jwt-token',
          'phone': '9876543210',
          'name': 'Amit Customer',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = HttpAuthRepository(
      client: client,
      baseUrl: 'https://example.test/',
    );
    final session = await repository.verifyOtp('9876543210', '654321');

    expect(session.phone, '9876543210');
    expect(session.name, 'Amit Customer');
    expect(session.token, 'jwt-token');
  });

  test('HTTP auth repository surfaces API errors', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'OTP expired.'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = HttpAuthRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    expect(
      () => repository.verifyOtp('9876543210', '654321'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'OTP expired.',
        ),
      ),
    );
  });
}
