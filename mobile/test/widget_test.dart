import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talegaon_fresh/main.dart';
import 'package:talegaon_fresh/product_api.dart';

class FakeProductRepository implements ProductRepository {
  @override
  Future<List<ApiProduct>> fetchProducts() async => const [
        ApiProduct(id: 1, name: 'Tomato', unit: '1 kg', price: 30, inStock: true),
        ApiProduct(id: 2, name: 'Potato', unit: '1 kg', price: 25, inStock: true),
      ];
}

void main() {
  testWidgets('Talegaon Fresh loads products from repository', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(repository: FakeProductRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Talegaon Fresh'), findsOneWidget);
    expect(find.text("Today's Fresh Products"), findsOneWidget);
    expect(find.text('Tomato'), findsWidgets);
    expect(find.text('₹30/1 kg'), findsWidgets);
  });
}
