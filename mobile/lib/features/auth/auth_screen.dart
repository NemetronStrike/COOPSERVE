import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../navigation/app_router.dart';
import '../../widgets/app_card.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(Icons.handshake_rounded,
                        color: scheme.onPrimary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COOPSERVE',
                          style: textTheme.titleLarge
                              ?.copyWith(color: scheme.primary)),
                      Text('Cooperative Services Platform',
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Welcome', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select your role to continue.',
                style: textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              // ── Role cards ───────────────────────────────────────────────
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'Customer',
                subtitle: 'Book household and community services',
                accentColor: AppColors.customerAccent,
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.customer),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.engineering_rounded,
                title: 'Worker',
                subtitle: 'Manage your jobs and earnings',
                accentColor: AppColors.workerAccent,
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.worker),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Cooperative Admin',
                subtitle: 'Oversee workers, bookings and disputes',
                accentColor: AppColors.adminAccent,
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.admin),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // ── SIH badge ────────────────────────────────────────────────
              Center(
                child: Text(
                  'Smart India Hackathon 2026 · SIH26089',
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(26),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}
