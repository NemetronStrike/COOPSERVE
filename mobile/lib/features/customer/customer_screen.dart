import 'package:flutter/material.dart';
import '../../core/app_spacing.dart';
import '../../widgets/app_empty_state.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
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
}
