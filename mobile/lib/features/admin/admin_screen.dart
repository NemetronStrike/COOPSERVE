import 'package:flutter/material.dart';
import '../../core/app_spacing.dart';
import '../../navigation/app_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_empty_state.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooperative Admin'),
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
          icon: Icons.admin_panel_settings_rounded,
          title: 'Admin Dashboard',
          subtitle: 'Worker management and oversight features coming soon.',
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
