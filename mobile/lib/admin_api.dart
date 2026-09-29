import 'dart:convert';

import 'package:http/http.dart' as http;

class AdminApiException implements Exception {
  const AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.name,
    required this.unit,
    this.price,
    this.stockQuantity,
    required this.inStock,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String unit;
  final double? price;
  final int? stockQuantity;
  final bool inStock;
  final String? imageUrl;

  factory AdminProduct.fromJson(Map<String, dynamic> json) => AdminProduct(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        unit: json['unit'] as String,
        price: json['price'] is num ? (json['price'] as num).toDouble() : null,
        stockQuantity: json['stock_quantity'] is num ? (json['stock_quantity'] as num).toInt() : null,
        inStock: json['in_stock'] as bool? ?? true,
        imageUrl: json['image_url'] as String?,
      );
}

class AdminOrder {
  const AdminOrder({
    required this.orderId,
    required this.customerId,
    required this.status,
    required this.allowedNextStatuses,
    required this.total,
    required this.address,
    this.paymentMethod,
    this.items = const [],
  });

  final int orderId;
  final String customerId;
  final String status;
  final List<String> allowedNextStatuses;
  final double total;
  final String address;
  final String? paymentMethod;
  final List<AdminOrderItem> items;

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        orderId: (json['order_id'] as num).toInt(),
        customerId: json['customer_id']?.toString() ?? '',
        status: json['status'] as String? ?? 'PENDING',
        allowedNextStatuses: (json['allowed_next_statuses'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        total: json['total'] is num ? (json['total'] as num).toDouble() : 0,
        address: json['address'] as String? ?? '',
        paymentMethod: json['payment_method'] as String?,
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AdminOrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class AdminOrderItem {
  const AdminOrderItem({required this.name, required this.quantity, required this.unitPrice, required this.lineTotal});
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) => AdminOrderItem(
        name: json['product'] as String? ?? '',
        quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
        unitPrice: json['unit_price'] is num ? (json['unit_price'] as num).toDouble() : 0,
        lineTotal: json['line_total'] is num ? (json['line_total'] as num).toDouble() : 0,
      );
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.todaysOrderCount,
    required this.todaysRevenue,
    required this.pendingOrders,
    required this.totalProducts,
    required this.outOfStockCount,
    required this.lowStockProducts,
  });

  final int todaysOrderCount;
  final double todaysRevenue;
  final int pendingOrders;
  final int totalProducts;
  final int outOfStockCount;
  final List<String> lowStockProducts;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) => AdminDashboardSummary(
        todaysOrderCount: (json['todays_order_count'] as num?)?.toInt() ?? 0,
        todaysRevenue: (json['todays_revenue'] as num?)?.toDouble() ?? 0,
        pendingOrders: (json['pending_orders'] as num?)?.toInt() ?? 0,
        totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
        outOfStockCount: (json['out_of_stock_count'] as num?)?.toInt() ?? 0,
        lowStockProducts: (json['low_stock_products'] as List? ?? [])
            .whereType<Map>()
            .map((e) => e['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList(),
      );
}

class HttpAdminRepository {
  HttpAdminRepository({
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
        'X-Admin-Token': token,
      };

  Future<List<AdminOrder>> listOrders({String? status}) async {
    final uri = Uri.parse('$_baseUrl/admin/orders').replace(
      queryParameters: status == null || status == 'ALL' ? null : {'status': status},
    );
    final response = await _client.get(uri, headers: _headers);
    final body = _success(response);
    final rows = body['orders'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => AdminOrder.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<AdminOrder> getOrder(int orderId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/admin/orders/$orderId'), headers: _headers);
    return AdminOrder.fromJson(_success(response));
  }

  Future<AdminOrder> updateOrderStatus(int orderId, String status) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/admin/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return AdminOrder.fromJson(_success(response));
  }

  Future<List<AdminProduct>> listInventory() async {
    final response = await _client.get(Uri.parse('$_baseUrl/admin/inventory'), headers: _headers);
    final body = _success(response);
    final rows = body['products'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => AdminProduct.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<AdminProduct> updateStock(int productId, int stockQuantity) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/admin/inventory/$productId'),
      headers: _headers,
      body: jsonEncode({'stock_quantity': stockQuantity}),
    );
    return AdminProduct.fromJson(_success(response));
  }

  Future<List<AdminProduct>> listPrices() async {
    final response = await _client.get(Uri.parse('$_baseUrl/admin/prices'), headers: _headers);
    final body = _success(response);
    final rows = body['products'];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => AdminProduct.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<AdminProduct> updatePrice(int productId, double price, {bool? inStock, String? imageUrl}) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/admin/prices/$productId'),
      headers: _headers,
      body: jsonEncode({
        'price': price,
        if (inStock != null) 'in_stock': inStock,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );
    return AdminProduct.fromJson(_success(response));
  }

  Future<AdminDashboardSummary> getDashboardSummary() async {
    final response = await _client.get(Uri.parse('$_baseUrl/admin/dashboard'), headers: _headers);
    return AdminDashboardSummary.fromJson(_success(response));
  }

  Future<AdminProduct> createProduct({
    required String name,
    required String unit,
    required double price,
    int stockQuantity = 0,
    String? imageUrl,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/admin/products'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'unit': unit,
        'price': price,
        'stock_quantity': stockQuantity,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );
    return AdminProduct.fromJson(_success(response));
  }

  Future<void> deleteProduct(int productId) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/admin/products/$productId'), headers: _headers);
    _success(response);
  }

  Map<String, dynamic> _success(http.Response response) {
    if (response.statusCode == 401) throw const AdminApiException('Invalid admin token.', statusCode: 401);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Admin API request failed.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] is String) message = decoded['detail'] as String;
      } catch (_) {}
      throw AdminApiException(message, statusCode: response.statusCode);
    }
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
