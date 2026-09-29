import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:talegaon_fresh/customer_api.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  const address = CustomerAddress(
    id: 42,
    label: 'Home',
    fullAddress: 'Main Road',
    city: 'Talegaon',
    pincode: '410507',
    landmark: 'Near Station',
    isDefault: true,
  );

  test('customer API updateAddress preserves server id and default flag', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.toString(), 'https://example.test/customers/me/addresses/42');
      expect(request.headers['authorization'], 'Bearer jwt-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['label'], 'Home');
      expect(body['address'], 'Main Road, Near Station');
      expect(body['city'], 'Talegaon');
      expect(body['pincode'], '410507');
      expect(body['is_default'], true);
      return http.Response(
        jsonEncode({'address': {
          'id': 42, 'label': 'Home', 'address': 'Main Road, Near Station',
          'city': 'Talegaon', 'pincode': '410507', 'is_default': true,
        }}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = HttpCustomerRepository(
      token: 'jwt-token', client: client, baseUrl: 'https://example.test',
    );
    final saved = await repository.updateAddress(address);
    expect(saved.id, 42);
    expect(saved.isDefault, true);
    expect(saved.fullAddress, 'Main Road, Near Station');
  });

  test('customer API updateAddress rejects an address without server id', () async {
    final repository = HttpCustomerRepository(
      token: 'jwt-token',
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'https://example.test',
    );
    const withoutId = CustomerAddress(
      label: 'Home', fullAddress: 'Main Road', city: 'Talegaon', pincode: '410507',
    );
    expect(
      () => repository.updateAddress(withoutId),
      throwsA(isA<CustomerApiException>().having(
        (e) => e.message, 'message', 'Address ID is required.',
      )),
    );
  });

  test('customer API maps cart rows to products and quantities', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://example.test/customers/me/cart');
      return http.Response(
        jsonEncode({'items': [
          {'name': 'Tomato', 'unit': 'kg', 'price': 40, 'quantity': 3},
        ]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = HttpCustomerRepository(
      token: 'jwt-token', client: client, baseUrl: 'https://example.test',
    );
    const product = Product(
      name: 'Tomato', unit: 'kg', price: 40, icon: Icons.local_grocery_store,
    );
    final cart = await repository.getCart([product]);
    expect(cart, hasLength(1));
    expect(cart.single.product.name, 'Tomato');
    expect(cart.single.quantity, 3);
  });


  test('order persistence preserves payment status and payment link', () {
    final original = OrderRecord(
      id: '1001',
      total: 120,
      payment: 'UPI',
      address: 'Main Road, Talegaon, 410507',
      createdAt: DateTime.parse('2026-09-29T10:00:00Z'),
      status: 'PAYMENT_PENDING',
      paymentLinkUrl: 'https://rzp.io/i/test-link',
      items: const [
        OrderLine(name: 'Tomato', unit: 'kg', price: 40, quantity: 3),
      ],
    );

    final restored = OrderRecord.fromJson(jsonDecode(jsonEncode(original.toJson())));
    expect(restored, isNotNull);
    expect(restored!.status, 'PAYMENT_PENDING');
    expect(restored.paymentLinkUrl, 'https://rzp.io/i/test-link');
    expect(restored.items.single.name, 'Tomato');
  });

  test('customer API sends authenticated order creation payload', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://example.test/customers/me/orders');
      expect(request.headers['authorization'], 'Bearer jwt-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['address_id'], 42);
      expect(body['payment_method'], 'COD');
      expect(body['items'], hasLength(1));
      return http.Response(
        jsonEncode({
          'order_id': 1001, 'total': 120,
          'address': 'Main Road, Talegaon, 410507',
          'payment_method': 'COD', 'status': 'CONFIRMED',
          'items': [
            {'name': 'Tomato', 'unit': 'kg', 'unit_price': 40, 'quantity': 3},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = HttpCustomerRepository(
      token: 'jwt-token', client: client, baseUrl: 'https://example.test',
    );
    const product = Product(
      name: 'Tomato', unit: 'kg', price: 40, icon: Icons.local_grocery_store,
    );
    final order = await repository.createOrder(
      [CartItem(product, 3)], address, 'COD',
    );
    expect(order.id, '1001');
    expect(order.status, 'CONFIRMED');
    expect(order.total, 120);
  });
}
