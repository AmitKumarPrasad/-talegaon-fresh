import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talegaon_fresh/auth_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('demo repository supports PIN registration', () async {
    const repository = DemoAuthRepository();
    final session = await repository.register('9876543210', '123456', 'Test Customer');
    expect(session.phone, '9876543210');
    expect(session.refreshToken, 'demo-refresh');
  });

  test('demo repository rejects invalid PIN', () async {
    const repository = DemoAuthRepository();
    expect(() => repository.login('9876543210', '000000'), throwsA(isA<AuthException>()));
  });

  test('HTTP repository sends secure PIN login request', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://example.test/auth/login');
      expect(jsonDecode(request.body), containsPair('phone', '9876543210'));
      expect(jsonDecode(request.body), containsPair('pin', '654321'));
      return http.Response(jsonEncode({
        'access_token': 'jwt-token',
        'refresh_token': 'refresh-token',
        'customer': {'phone': '9876543210', 'name': 'Amit Customer'}
      }), 200, headers: {'content-type':'application/json'});
    });
    final repository = HttpAuthRepository(client: client, baseUrl: 'https://example.test');
    final session = await repository.login('9876543210', '654321');
    expect(session.token, 'jwt-token');
    expect(session.refreshToken, 'refresh-token');
  });
}
