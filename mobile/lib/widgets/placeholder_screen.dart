import 'package:flutter/material.dart';
import '../core/app_spacing.dart';
import 'app_empty_state.dart';

/// Generic placeholder screen used by feature routes during development.
class PlaceholderScreen extends StatelessWidget {
  final String label;
  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppEmptyState(
          icon: Icons.construction_rounded,
          title: label,
          subtitle: 'This section is under development.',
        ),
      ),
    );
  }
}
