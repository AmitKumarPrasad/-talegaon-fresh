import 'dart:convert';

import 'package:http/http.dart' as http;

import 'main.dart';

abstract class AddressRepository {
  Future<List<CustomerAddress>> fetchAddresses();
  Future<CustomerAddress> createAddress(CustomerAddress address);
  Future<CustomerAddress> updateAddress(String id, CustomerAddress address);
  Future<void> deleteAddress(String id);
}

class AddressApiException implements Exception {
  const AddressApiException(this.message);
  final String message;
}

class HttpAddressRepository implements AddressRepository {
  HttpAddressRepository({
    http.Client? client,
    String? baseUrl,
    required this.token,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://talegaon-fresh-ai-backend.onrender.com',
        )).replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;
  final String? token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _uri([String suffix = '']) => Uri.parse('$_baseUrl/customers/me/addresses$suffix');

  @override
  Future<List<CustomerAddress>> fetchAddresses() async {
    final response = await _client.get(_uri(), headers: _headers);
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final raw = decoded is Map ? decoded['addresses'] : decoded;
    if (raw is! List) {
      throw const AddressApiException('Invalid address API response.');
    }
    return raw.map(CustomerAddress.fromJson).whereType<CustomerAddress>().toList();
  }

  @override
  Future<CustomerAddress> createAddress(CustomerAddress address) async {
    final response = await _client.post(
      _uri(),
      headers: _headers,
      body: jsonEncode(address.toJson()),
    );
    _ensureSuccess(response);
    return _parseAddress(response.body);
  }

  @override
  Future<CustomerAddress> updateAddress(String id, CustomerAddress address) async {
    final response = await _client.put(
      _uri('/$id'),
      headers: _headers,
      body: jsonEncode(address.toJson()),
    );
    _ensureSuccess(response);
    return _parseAddress(response.body);
  }

  @override
  Future<void> deleteAddress(String id) async {
    final response = await _client.delete(_uri('/$id'), headers: _headers);
    _ensureSuccess(response);
  }

  CustomerAddress _parseAddress(String body) {
    final decoded = jsonDecode(body);
    final raw = decoded is Map && decoded['address'] != null ? decoded['address'] : decoded;
    final address = CustomerAddress.fromJson(raw);
    if (address == null) {
      throw const AddressApiException('Invalid address API response.');
    }
    return address;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode == 401) {
      throw const AddressApiException('AUTH_UNAUTHORIZED');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AddressApiException('Address API returned HTTP ${response.statusCode}.');
    }
  }
}
