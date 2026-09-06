import 'package:flutter/material.dart';
import '../../core/app_spacing.dart';
import '../../widgets/app_empty_state.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cooperative Admin')),
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
}
