import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../navigation/app_router.dart';
import '../../services/auth_service.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminDashboardStats? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await AdminService().getDashboard();
      if (mounted) setState(() => _stats = stats);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooperative Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _stats == null && _error == null
          ? const AppLoading(message: 'Loading admin dashboard')
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _buildDashboard(context, _stats!),
    );
  }

  Widget _buildDashboard(BuildContext context, AdminDashboardStats stats) {
    Widget metric(String label, int value) => AppCard(
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        metric('Customers', stats.totalCustomers),
        metric('Workers', stats.totalWorkers),
        metric('Verified workers', stats.verifiedWorkers),
        metric('Pending verification', stats.pendingWorkerVerifications),
        metric('Total bookings', stats.totalBookings),
        metric('Pending bookings', stats.pendingBookings),
        metric('Completed bookings', stats.completedBookings),
        metric('Payments', stats.totalPayments),
        const SizedBox(height: AppSpacing.sm),
        AppCardOutlined(
          onTap: () => Navigator.pushNamed(context, '/admin/workers'),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Worker Verification')),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
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
