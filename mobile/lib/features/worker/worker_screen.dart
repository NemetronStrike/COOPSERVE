import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../navigation/app_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';

class WorkerScreen extends StatelessWidget {
  const WorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            const AppEmptyState(
              icon: Icons.engineering_rounded,
              title: 'Worker Dashboard',
              subtitle: 'Manage your assigned service bookings.',
            ),
            AppCardOutlined(
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.workerBookings),
              child: const Row(
                children: [
                  Icon(Icons.event_note_rounded),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('My Bookings')),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.roleSelection,
        (_) => false,
      );
    }
  }
}
