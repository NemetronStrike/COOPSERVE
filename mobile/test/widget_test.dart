import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coopserve/features/auth/screens/role_selection_screen.dart';
import 'package:coopserve/features/auth/screens/splash_screen.dart';
import 'package:coopserve/models/user_role.dart';

void main() {
  testWidgets('Splash screen renders COOPSERVE branding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const SplashScreen(delay: Duration.zero),
          '/role-selection': (_) => const RoleSelectionScreen(),
        },
      ),
    );
    // Verify branding on first frame.
    expect(find.text('COOPSERVE'), findsOneWidget);
    expect(
      find.text('Cooperative Workforce · Community Services'),
      findsOneWidget,
    );
    // Fire the zero-duration timer and settle navigation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Role selection screen renders all three roles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionScreen()),
    );
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Cooperative Admin'), findsOneWidget);
  });

  testWidgets('UserRole labels are correct', (_) async {
    expect(UserRole.customer.label, 'Customer');
    expect(UserRole.worker.label, 'Worker');
    expect(UserRole.admin.label, 'Cooperative Admin');
  });
}
