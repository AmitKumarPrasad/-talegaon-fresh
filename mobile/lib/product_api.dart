import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiProduct {
  const ApiProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.inStock,
  });

  final int id;
  final String name;
  final String unit;
  final double price;
  final bool inStock;

  factory ApiProduct.fromJson(Map<String, dynamic> json) => ApiProduct(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        unit: json['unit'] as String,
        price: (json['price'] as num).toDouble(),
        inStock: json['in_stock'] as bool? ?? true,
      );
}

class ApiUnauthorizedException implements Exception {
  const ApiUnauthorizedException();
}

abstract class ProductRepository {
  Future<List<ApiProduct>> fetchProducts();
}

class HttpProductRepository implements ProductRepository {
  HttpProductRepository({
    http.Client? client,
    String? baseUrl,
    String? token,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'https://talegaon-fresh-ai-backend.onrender.com',
                ))
            .replaceFirst(RegExp(r'/+$'), ''),
        _token = token;

  final http.Client _client;
  final String _baseUrl;
  final String? _token;

  @override
  Future<List<ApiProduct>> fetchProducts() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Accept': 'application/json',
        if (_token != null && _token.isNotEmpty)
          'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 401) {
      throw const ApiUnauthorizedException();
    }
    if (response.statusCode != 200) {
      throw Exception('Product API returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['products'] is! List) {
      throw const FormatException('Invalid product API response.');
    }

    return (decoded['products'] as List)
        .whereType<Map>()
        .map((item) => ApiProduct.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
