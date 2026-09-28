import 'dart:convert';

import 'package:http/http.dart' as http;

import 'main.dart';

class CartApiException implements Exception {
  const CartApiException(this.message);
  final String message;

  @override
  String toString() => 'CartApiException: $message';
}

class CartLine {
  const CartLine({
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  final String name;
  final String unit;
  final double price;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'price': price,
        'quantity': quantity,
      };

  static CartLine? fromJson(dynamic value) {
    if (value is! Map) return null;
    final name = value['name'];
    final unit = value['unit'];
    final price = value['price'];
    final quantity = value['quantity'];
    if (name is! String ||
        unit is! String ||
        price is! num ||
        quantity is! num ||
        quantity < 1) {
      return null;
    }
    return CartLine(
      name: name,
      unit: unit,
      price: price.toDouble(),
      quantity: quantity.toInt(),
    );
  }

  factory CartLine.fromCartItem(CartItem item) => CartLine(
        name: item.product.name,
        unit: item.product.unit,
        price: item.product.price,
        quantity: item.quantity,
      );
}

abstract class CartRepository {
  Future<List<CartLine>> fetchCart();
  Future<List<CartLine>> replaceCart(List<CartLine> items);
  Future<void> clearCart();
}

class HttpCartRepository implements CartRepository {
  HttpCartRepository({String? baseUrl, this.token, http.Client? client})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue:
                  'https://talegaon-fresh-ai-backend.onrender.com',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<List<CartLine>> fetchCart() async {
    final response =
        await _client.get(_uri('/customers/me/cart'), headers: _headers);
    _ensureSuccess(response);
    return _decodeItems(response.body);
  }

  @override
  Future<List<CartLine>> replaceCart(List<CartLine> items) async {
    final response = await _client.put(
      _uri('/customers/me/cart'),
      headers: _headers,
      body: jsonEncode({'items': items.map((item) => item.toJson()).toList()}),
    );
    _ensureSuccess(response);
    return _decodeItems(response.body);
  }

  @override
  Future<void> clearCart() async {
    final response =
        await _client.delete(_uri('/customers/me/cart'), headers: _headers);
    _ensureSuccess(response);
  }

  List<CartLine> _decodeItems(String body) {
    final decoded = jsonDecode(body);
    final values = decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : decoded is List
            ? decoded
            : const [];
    return values.map(CartLine.fromJson).whereType<CartLine>().toList();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode == 401) {
      throw const CartApiException('AUTH_UNAUTHORIZED');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'CART_API_ERROR';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'] as String;
        } else if (decoded is Map && decoded['error'] is String) {
          message = decoded['error'] as String;
        }
      } catch (_) {}
      throw CartApiException(message);
    }
  }
}
