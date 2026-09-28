import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talegaon_fresh/main.dart';
import 'package:talegaon_fresh/product_api.dart';

class ProductDetailsFakeRepository implements ProductRepository {
  @override
  Future<List<ApiProduct>> fetchProducts() async => const [
    ApiProduct(id: 1, name: 'Tomato', unit: '1 kg', price: 30, inStock: true),
  ];
}

void main() {
  testWidgets('customer can open product details and add selected quantity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          repository: ProductDetailsFakeRepository(),
          session: const CustomerSession(
            phone: '9876543210',
            name: 'Talegaon Customer',
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    final productCard = find.widgetWithText(ProductCard, 'Tomato');
    await tester.ensureVisible(productCard);
    await tester.tap(productCard);
    await tester.pumpAndSettle();

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('₹30 / 1 kg'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹60'), findsOneWidget);
    await tester.tap(find.text('Add 2 to Cart'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
