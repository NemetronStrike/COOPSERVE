import 'package:flutter/material.dart';
import '../../core/app_spacing.dart';
import '../../navigation/app_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_empty_state.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppEmptyState(
          icon: Icons.person_rounded,
          title: 'Customer Dashboard',
          subtitle: 'Booking and service features coming soon.',
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRouter.roleSelection, (_) => false);
    }
  }
}
