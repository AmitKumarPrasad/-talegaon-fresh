import 'package:flutter_test/flutter_test.dart';
import 'package:talegaon_fresh/main.dart';

void main() {
  testWidgets('Talegaon Fresh home screen renders', (tester) async {
    await tester.pumpWidget(const TalegaonFreshApp());
    expect(find.text('Talegaon Fresh'), findsOneWidget);
    expect(find.text("Today's Fresh Products"), findsOneWidget);
    expect(find.text('Tomato'), findsWidgets);
  });
}
