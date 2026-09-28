import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  testWidgets('customer can view order item details', (tester) async {
    final order = OrderRecord(
      id: 'TF123456',
      total: 80,
      payment: 'COD',
      address: 'Talegaon Dabhade, Pune, 410507',
      createdAt: DateTime(2026, 9, 28, 18, 30),
      items: const [
        OrderLine(name: 'Tomato', unit: '1 kg', price: 30, quantity: 2),
        OrderLine(name: 'Potato', unit: '1 kg', price: 20, quantity: 1),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: OrderDetailsPage(order: order)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order #TF123456'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('2 × ₹30 / 1 kg'), findsOneWidget);
    expect(find.text('₹60'), findsOneWidget);
    expect(find.text('Potato'), findsOneWidget);
    expect(find.text('Order Total'), findsOneWidget);
    expect(find.text('₹80'), findsOneWidget);
    expect(find.text('Track Order'), findsOneWidget);
  });
}
