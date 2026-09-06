import 'package:flutter/material.dart';
import '../features/auth/auth_screen.dart';
import '../features/customer/customer_screen.dart';
import '../features/worker/worker_screen.dart';
import '../features/admin/admin_screen.dart';

class AppRouter {
  static const initial = '/';
  static const customer = '/customer';
  static const worker = '/worker';
  static const admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
        initial: (_) => const AuthScreen(),
        customer: (_) => const CustomerScreen(),
        worker: (_) => const WorkerScreen(),
        admin: (_) => const AdminScreen(),
      };
}
