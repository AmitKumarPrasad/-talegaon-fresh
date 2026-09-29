import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class CustomerApiException implements Exception {
  const CustomerApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class HttpCustomerRepository {
  HttpCustomerRepository({
    required this.token,
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://talegaon-fresh-ai-backend.onrender.com',
        )).replaceFirst(RegExp(r'/+$'), '');

  final String token;
  final http.Client _client;
  final String _baseUrl;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> logout() async {
    final response = await _client.post(Uri.parse("$_baseUrl/auth/logout"), headers: _headers);
    _success(response);
  }

  Future<List<CustomerAddress>> getAddresses() async {
    final response = await _client.get(Uri.parse('$_baseUrl/customers/me/addresses'), headers: _headers);
    final body = _success(response);
    final rows = body['addresses'];
    if (rows is! List) return [];
    return rows.map(CustomerAddress.fromApiJson).whereType<CustomerAddress>().toList();
  }

  Future<CustomerAddress> createAddress(CustomerAddress address) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/customers/me/addresses'),
      headers: _headers,
      body: jsonEncode(address.toApiJson()),
    );
    final body = _success(response);
    return CustomerAddress.fromApiJson(body['address'])!;
  }

  Future<CustomerAddress> updateAddress(CustomerAddress address) async {
    if (address.id == null) throw const CustomerApiException('Address ID is required.');
    final response = await _client.put(
      Uri.parse('$_baseUrl/customers/me/addresses/${address.id}'),
      headers: _headers,
      body: jsonEncode(address.toApiJson()),
    );
    final body = _success(response);
    return CustomerAddress.fromApiJson(body['address'])!;
  }

  Future<void> deleteAddress(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/customers/me/addresses/$id'), headers: _headers);
    _success(response);
  }

  Future<List<CartItem>> getCart(List<Product> products) async {
    final response = await _client.get(Uri.parse('$_baseUrl/customers/me/cart'), headers: _headers);
    final body = _success(response);
    final rows = body['items'];
    if (rows is! List) return [];
    final result = <CartItem>[];
    for (final row in rows) {
      if (row is! Map || row['name'] is! String || row['unit'] is! String || row['price'] is! num || row['quantity'] is! num) continue;
      final name = row['name'] as String;
      final matches = products.where((p) => p.name.toLowerCase() == name.toLowerCase()).toList();
      final product = (matches.isNotEmpty ? matches.first : null) ?? Product(name: name, unit: row['unit'] as String, price: (row['price'] as num).toDouble(), icon: Icons.local_grocery_store);
      result.add(CartItem(product, (row['quantity'] as num).toInt()));
    }
    return result;
  }

  Future<void> replaceCart(List<CartItem> cart) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/customers/me/cart'),
      headers: _headers,
      body: jsonEncode({'items': cart.map((item) => {
        'name': item.product.name,
        'unit': item.product.unit,
        'price': item.product.price,
        'quantity': item.quantity,
      }).toList()}),
    );
    _success(response);
  }

  Future<void> clearCart() async {
    final response = await _client.delete(Uri.parse('$_baseUrl/customers/me/cart'), headers: _headers);
    _success(response);
  }

  Future<OrderRecord> createOrder(List<CartItem> cart, CustomerAddress address, String payment) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/customers/me/orders'),
      headers: _headers,
      body: jsonEncode({
        'items': cart.map((item) => {
          'name': item.product.name,
          'unit': item.product.unit,
          'price': item.product.price,
          'quantity': item.quantity,
        }).toList(),
        if (address.id != null) 'address_id': address.id,
        'payment_method': payment,
      }),
    );
    return _orderFromApi(_success(response));
  }

  Future<OrderRecord> getOrder(int orderId) async {
    final response = await _client.get(Uri.parse("$_baseUrl/customers/me/orders/$orderId"), headers: _headers);
    return _orderFromApi(_success(response));
  }

  Future<List<OrderRecord>> getOrders() async {
    final response = await _client.get(Uri.parse('$_baseUrl/customers/me/orders'), headers: _headers);
    final body = _success(response);
    final rows = body['orders'];
    if (rows is! List) return [];
    return rows.map((row) => row is Map ? OrderRecord.fromApiJson(row) : null).whereType<OrderRecord>().toList();
  }

  Map<String, dynamic> _success(http.Response response) {
    if (response.statusCode == 401) throw const CustomerApiException('Session expired.', statusCode: 401);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Customer API request failed.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] is String) message = body['detail'] as String;
      } catch (_) {}
      throw CustomerApiException(message, statusCode: response.statusCode);
    }
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  OrderRecord _orderFromApi(Map<String, dynamic> value) => OrderRecord.fromApiJson(value);
}
