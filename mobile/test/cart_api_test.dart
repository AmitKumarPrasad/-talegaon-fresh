import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../lib/cart_api.dart';

void main() {
  const line = CartLine(
    name: 'Tomato',
    unit: '1 kg',
    price: 40,
    quantity: 2,
  );

  test('fetch cart sends bearer token and parses items', () async {
    late http.Request captured;
    final repository = HttpCartRepository(
      baseUrl: 'https://api.example.com',
      token: 'jwt-123',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'items': [line.toJson()]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repository.fetchCart();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/customers/me/cart');
    expect(captured.headers['authorization'], 'Bearer jwt-123');
    expect(result.single.name, 'Tomato');
    expect(result.single.quantity, 2);
  });

  test('replace cart sends all cart lines', () async {
    late http.Request captured;
    final repository = HttpCartRepository(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'items': [line.toJson()]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await repository.replaceCart([line]);

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/customers/me/cart');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['items'] as List).single['quantity'], 2);
    expect(result.single.unit, '1 kg');
  });

  test('clear cart sends delete request', () async {
    late http.Request captured;
    final repository = HttpCartRepository(
      baseUrl: 'https://api.example.com',
      token: 'jwt-123',
      client: MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      }),
    );

    await repository.clearCart();

    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/customers/me/cart');
    expect(captured.headers['authorization'], 'Bearer jwt-123');
  });

  test('maps unauthorized response', () async {
    final repository = HttpCartRepository(
      baseUrl: 'https://api.example.com',
      client: MockClient((_) async => http.Response('Unauthorized', 401)),
    );

    expect(
      () => repository.fetchCart(),
      throwsA(
        isA<CartApiException>().having(
          (error) => error.message,
          'message',
          'AUTH_UNAUTHORIZED',
        ),
      ),
    );
  });
}
