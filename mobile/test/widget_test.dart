import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  testWidgets('FRESHORA starts with customer authentication', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TalegaonFreshApp());
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Welcome back. Sign in securely.'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.enterText(find.byType(TextField).last, '123456');
    final signInButton = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();
    expect(find.text('FRESHORA'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
  });

  testWidgets('customer can manage saved addresses', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          repository: FakeProductRepository(),
          session: const CustomerSession(
            phone: '9876543210',
            name: 'Talegaon Customer',
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Addresses'));
    await tester.pumpAndSettle();

    expect(find.text('No saved addresses yet.'), findsOneWidget);
    expect(find.text('Add Address'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains('Talegaon Dabhade') == true,
      ),
      findsNothing,
    );

    await tester.tap(find.text('Add Address'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Work');
    await tester.enterText(fields.at(1), 'Office Road');
    await tester.enterText(fields.at(2), 'Talegaon');
    await tester.enterText(fields.at(3), '410507');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.textContaining('Office Road'), findsOneWidget);
  });

  testWidgets('FRESHORA loads products from repository', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          repository: FakeProductRepository(),
          session: const CustomerSession(
            phone: '9876543210',
            name: 'Talegaon Customer',
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FRESHORA'), findsOneWidget);
    expect(find.text("Today's Fresh Products"), findsOneWidget);
    expect(find.text('Tomato'), findsWidgets);
    expect(find.text('₹30/1 kg'), findsWidgets);
  });

  testWidgets('customer cart persists across app sessions', (tester) async {
    SharedPreferences.setMockInitialValues({});

    Widget buildShell() => MaterialApp(
          home: AppShell(
            repository: FakeProductRepository(),
            session: const CustomerSession(
              phone: '9876543210',
              name: 'Talegaon Customer',
              token: 'test-token',
            ),
          ),
        );

    await tester.pumpWidget(buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    final addButton = find.widgetWithText(FilledButton, 'Add').first;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
