import 'package:flutter/material.dart';
import '../../../core/app_spacing.dart';
import '../../../models/user_role.dart';
import 'role_badge.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final UserRole? role;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.handshake_rounded,
                  color: scheme.onPrimary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'COOPSERVE',
              style: textTheme.titleMedium?.copyWith(color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (role != null) ...[
          RoleBadge(role: role!),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
