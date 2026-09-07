import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customer/customer_screen.dart';
import '../features/customer/service_catalog_screen.dart';
import '../features/customer/service_details_screen.dart';
import '../features/customer/worker_details_screen.dart';
import '../features/worker/worker_screen.dart';
import '../features/admin/admin_screen.dart';
import '../models/user_role.dart';

class AppRouter {
  // ── Route names ────────────────────────────────────────────────────────────
  static const String initial = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String customer = '/customer';
  static const String serviceCatalog = '/customer/services';
  static const String serviceDetails = '/customer/services/details';
  static const String workerDetails = '/customer/workers/details';
  static const String worker = '/worker';
  static const String admin = '/admin';

  // ── Route map ──────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        initial: (_) => const SplashScreen(),
        roleSelection: (_) => const RoleSelectionScreen(),
        customer: (_) => const CustomerScreen(),
        serviceCatalog: (_) => ServiceCatalogScreen(),
        worker: (_) => const WorkerScreen(),
        admin: (_) => const AdminScreen(),
      };

  // ── onGenerateRoute — handles routes that require arguments ────────────────
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        final role = settings.arguments as UserRole?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginScreen(role: role ?? UserRole.customer),
        );
      case register:
        final role = settings.arguments as UserRole?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterScreen(role: role ?? UserRole.customer),
        );
      case serviceDetails:
        final service = settings.arguments;
        if (service is! int || service < 1) return null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ServiceDetailsScreen(serviceId: service),
        );
      case workerDetails:
        final workerId = settings.arguments;
        if (workerId is! int || workerId < 1) return null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WorkerDetailsScreen(workerId: workerId),
        );
      default:
        return null;
    }
  }
}
