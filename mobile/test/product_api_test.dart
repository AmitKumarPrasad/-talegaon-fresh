import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talegaon_fresh/product_api.dart';

void main() {
  test('product API sends bearer token when provided', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://example.test/products');
      expect(request.headers['authorization'], 'Bearer jwt-token');
      return http.Response(
        jsonEncode({
          'products': [
            {
              'id': 1,
              'name': 'Tomato',
              'unit': '1 kg',
              'category': 'Vegetables',
              'price': 30,
              'mrp': 35,
              'in_stock': true,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = HttpProductRepository(
      client: client,
      baseUrl: 'https://example.test/',
      token: 'jwt-token',
    );

    final products = await repository.fetchProducts();
    expect(products.single.name, 'Tomato');
    expect(products.single.category, 'Vegetables');
    expect(products.single.mrp, 35);
  });

  test('product API defaults missing category for backward compatibility', () {
    final product = ApiProduct.fromJson({
      'id': 99,
      'name': 'Legacy Item',
      'unit': '1 pc',
      'price': 10,
      'in_stock': true,
    });
    expect(product.category, 'Other');
    expect(product.mrp, isNull);
  });

  test('product API omits authorization header without a token', () async {
    final client = MockClient((request) async {
      expect(request.headers.containsKey('authorization'), isFalse);
      return http.Response(
        jsonEncode({'products': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = HttpProductRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    expect(await repository.fetchProducts(), isEmpty);
  });
  test('product API exposes unauthorized responses as a typed error', () async {
    final client = MockClient((request) async {
      return http.Response('', 401);
    });

    final repository = HttpProductRepository(
      client: client,
      baseUrl: 'https://example.test',
      token: 'expired-token',
    );

    expect(
      repository.fetchProducts,
      throwsA(isA<ApiUnauthorizedException>()),
    );
  });
}
