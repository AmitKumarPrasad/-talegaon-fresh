import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  testWidgets('customer can select quantity on product details', (tester) async {
    const product = Product(
      name: 'Tomato',
      unit: '1 kg',
      price: 30,
      icon: Icons.circle,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(
          product: product,
          onAdd: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('₹30 / 1 kg'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹60'), findsOneWidget);

  });
}
