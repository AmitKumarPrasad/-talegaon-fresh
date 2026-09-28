import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  testWidgets('customer can view and remove a favorite product', (tester) async {
    const product = Product(
      name: 'Tomato',
      unit: '1 kg',
      price: 30,
      icon: Icons.circle,
    );
    var toggled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesPage(
          products: const [product],
          onAdd: (_) {},
          onToggleFavorite: (_) => toggled++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    expect(toggled, 1);
  });
}
