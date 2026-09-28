import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talegaon_fresh/product_api.dart';

void main() {
  test('product API reports expired authentication on HTTP 401', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer expired-token');
      return http.Response(
        jsonEncode({'detail': 'Token expired.'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = HttpProductRepository(
      client: client,
      baseUrl: 'https://example.test',
      token: 'expired-token',
    );

    expect(
      () => repository.fetchProducts(),
      throwsA(isA<AuthenticationExpiredException>()),
    );
  });
}
