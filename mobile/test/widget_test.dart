import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coopserve/features/auth/screens/role_selection_screen.dart';
import 'package:coopserve/features/auth/screens/splash_screen.dart';
import 'package:coopserve/features/customer/customer_screen.dart';
import 'package:coopserve/features/customer/service_catalog_screen.dart';
import 'package:coopserve/features/customer/service_details_screen.dart';
import 'package:coopserve/models/service_listing.dart';
import 'package:coopserve/models/user_role.dart';
import 'package:coopserve/navigation/app_router.dart';

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

  testWidgets('Customer dashboard starts with a loading state',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerScreen()),
    );
    await tester.pump();

    expect(find.text('Preparing your services'), findsOneWidget);
  });

  testWidgets('Service catalog renders services and opens details',
      (tester) async {
    final service = _testService();
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogScreen(
          loadServices: ({search, category}) async => [service],
        ),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Services'), findsOneWidget);
    expect(find.text(service.name), findsOneWidget);
    expect(find.text(service.category), findsWidgets);

    final route = AppRouter.onGenerateRoute(
      RouteSettings(
        name: AppRouter.serviceDetails,
        arguments: service.id,
      ),
    );
    expect(route, isA<MaterialPageRoute<dynamic>>());

    await tester.pumpWidget(
      MaterialApp(
        home: ServiceDetailsScreen(
          serviceId: service.id,
          loadService: (_) async => service,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ServiceDetailsScreen), findsOneWidget);
    expect(find.text('Continue to booking'), findsOneWidget);
  });

  testWidgets('Service catalog combines search and category filters',
      (tester) async {
    final cleaning = _testService(
      name: 'Home cleaning',
      category: 'Cleaning',
      description: 'Trusted help for a fresh home.',
    );
    final electrician = _testService(
      name: 'Electrician',
      category: 'Repairs',
      description: 'Skilled electrical support.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogScreen(
          loadServices: ({search, category}) async {
            final services = [cleaning, electrician];
            return services.where((service) {
              final matchesSearch = search == null ||
                  '${service.name} ${service.description}'
                      .toLowerCase()
                      .contains(search.toLowerCase());
              final matchesCategory = category == null ||
                  service.category.toLowerCase() == category.toLowerCase();
              return matchesSearch && matchesCategory;
            }).toList();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'FRESH',
    );
    await tester.pump();
    expect(find.text(cleaning.name), findsOneWidget);
    expect(find.text(electrician.name), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Repairs'));
    await tester.pump();
    expect(find.text(electrician.name), findsOneWidget);
    expect(find.text(cleaning.name), findsNothing);
  });

  testWidgets('Service catalog shows an empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogScreen(
          loadServices: ({search, category}) async =>
              search == null ? [_testService()] : [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'does not exist');
    await tester.pump();

    expect(find.text('No services found'), findsOneWidget);
    expect(find.text('Try a different search or category.'), findsOneWidget);
  });

  testWidgets('UserRole labels are correct', (_) async {
    expect(UserRole.customer.label, 'Customer');
    expect(UserRole.worker.label, 'Worker');
    expect(UserRole.admin.label, 'Cooperative Admin');
  });
}

ServiceListing _testService({
  int id = 1,
  String name = 'Home cleaning',
  String category = 'Cleaning',
  String description = 'Trusted help for a fresh, comfortable home.',
}) {
  return ServiceListing(
    id: id,
    name: name,
    category: category,
    description: description,
    priceLabel: 'From Rs. 499',
    rating: 4.8,
    reviewCount: 12,
    iconName: 'cleaning',
  );
}
