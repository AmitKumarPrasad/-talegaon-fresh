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
  testWidgets('Talegaon Fresh starts with customer authentication', (tester) async {
    await tester.pumpWidget(const TalegaonFreshApp());
    expect(find.text('Welcome to Talegaon Fresh'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verify & Continue'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Talegaon Fresh'), findsOneWidget);
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

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains('Talegaon Dabhade') == true,
      ),
      findsOneWidget,
    );
    expect(find.text('Add Address'), findsOneWidget);

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
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains('Office Road') == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Talegaon Fresh loads products from repository', (tester) async {
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
    expect(find.text('Talegaon Fresh'), findsOneWidget);
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
    final addButton = find.widgetWithText(FilledButton, 'Add').first;
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });


}
