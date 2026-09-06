import 'package:flutter/material.dart';
import '../../core/app_spacing.dart';
import '../../widgets/app_empty_state.dart';

class WorkerScreen extends StatelessWidget {
  const WorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppEmptyState(
          icon: Icons.engineering_rounded,
          title: 'Worker Dashboard',
          subtitle: 'Job management and earnings features coming soon.',
        ),
      ),
    );
  }
}
