import 'package:flutter_test/flutter_test.dart';
import 'package:coopserve/core/app.dart';

void main() {
  testWidgets('Auth screen renders all three role cards', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());

    expect(find.text('COOPSERVE'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Cooperative Admin'), findsOneWidget);
  });
}
