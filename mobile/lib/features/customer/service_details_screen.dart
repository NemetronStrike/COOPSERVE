import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/service_listing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceListing service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _serviceIcon(),
                const SizedBox(height: AppSpacing.md),
                Text(service.name, style: AppTextStyles.headlineSmall(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(service.category, style: AppTextStyles.labelLarge(context)),
                const SizedBox(height: AppSpacing.md),
                Text(service.description, style: AppTextStyles.bodyLarge(context)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${service.rating} (${service.reviewCount} reviews)'),
                    const Spacer(),
                    Text(service.priceLabel, style: AppTextStyles.titleMedium(context)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('About this service', style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This service is provided by verified cooperative workers. '
            'Availability and final pricing will be confirmed before booking.',
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Continue to booking',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking will be available soon.')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceIcon() {
    return CircleAvatar(
      radius: AppSpacing.avatarSizeLarge / 2,
      backgroundColor: AppColors.customerAccent.withAlpha(28),
      child: Icon(Icons.home_repair_service_rounded, color: AppColors.customerAccent, size: AppSpacing.iconSizeLarge),
    );
  }
}