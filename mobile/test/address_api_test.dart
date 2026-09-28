import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talegaon_fresh/address_api.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  const address = CustomerAddress(
    label: 'Home',
    fullAddress: 'Talegaon Dabhade',
    city: 'Pune',
    pincode: '410507',
    landmark: 'Near station',
  );

  test('address API fetches addresses with bearer token', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.test/customers/me/addresses');
      expect(request.headers['authorization'], 'Bearer jwt-token');
      return http.Response(jsonEncode({'addresses': [address.toJson()]}), 200);
    });
    final repo = HttpAddressRepository(client: client, baseUrl: 'https://example.test', token: 'jwt-token');
    final result = await repo.fetchAddresses();
    expect(result.single.displayAddress, address.displayAddress);
  });

  test('address API creates an address', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), address.toJson());
      return http.Response(jsonEncode({'address': address.toJson()}), 201);
    });
    final repo = HttpAddressRepository(client: client, baseUrl: 'https://example.test', token: 'jwt-token');
    expect((await repo.createAddress(address)).label, 'Home');
  });

  test('address API updates and deletes an address', () async {
    var call = 0;
    final client = MockClient((request) async {
      call++;
      if (call == 1) {
        expect(request.method, 'PUT');
        expect(request.url.toString(), 'https://example.test/customers/me/addresses/42');
        return http.Response(jsonEncode({'address': address.toJson()}), 200);
      }
      expect(request.method, 'DELETE');
      expect(request.url.toString(), 'https://example.test/customers/me/addresses/42');
      return http.Response('', 204);
    });
    final repo = HttpAddressRepository(client: client, baseUrl: 'https://example.test', token: 'jwt-token');
    expect((await repo.updateAddress('42', address)).pincode, '410507');
    await repo.deleteAddress('42');
  });

  test('address API maps unauthorized response', () async {
    final client = MockClient((request) async => http.Response('', 401));
    final repo = HttpAddressRepository(client: client, baseUrl: 'https://example.test', token: 'expired');
    expect(repo.fetchAddresses, throwsA(isA<AddressApiException>()));
  });
}
