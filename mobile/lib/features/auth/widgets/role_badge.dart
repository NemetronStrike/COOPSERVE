import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_spacing.dart';
import '../../../models/user_role.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  Color _accentFor(UserRole r) {
    switch (r) {
      case UserRole.customer:
        return AppColors.customerAccent;
      case UserRole.worker:
        return AppColors.workerAccent;
      case UserRole.admin:
        return AppColors.adminAccent;
    }
  }

  IconData _iconFor(UserRole r) {
    switch (r) {
      case UserRole.customer:
        return Icons.person_rounded;
      case UserRole.worker:
        return Icons.engineering_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: accent.withAlpha(26),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: accent.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(role), size: 14, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
