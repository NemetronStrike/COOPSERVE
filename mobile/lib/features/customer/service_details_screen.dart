import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/service_listing.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  final Future<ServiceListing> Function(int serviceId) loadService;

  ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    Future<ServiceListing> Function(int serviceId)? loadService,
  }) : loadService = loadService ?? CustomerService().getServiceDetails;

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  ServiceListing? _service;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    setState(() => _errorMessage = null);
    try {
      final service = await widget.loadService(widget.serviceId);
      if (!mounted) return;
      setState(() => _service = service);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'We could not load this service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service details')),
      body: _service == null && _errorMessage == null
          ? const AppLoading(message: 'Loading service details')
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadService)
              : _buildDetails(context, _service!),
    );
  }

  Widget _buildDetails(BuildContext context, ServiceListing service) {
    return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _serviceIcon(service),
                const SizedBox(height: AppSpacing.md),
                Text(service.name,
                  style: AppTextStyles.headlineSmall(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(service.category,
                  style: AppTextStyles.labelLarge(context)),
                const SizedBox(height: AppSpacing.md),
                Text(service.description,
                  style: AppTextStyles.bodyLarge(context)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${service.rating} (${service.reviewCount} reviews)'),
                    const Spacer(),
                    Text(service.priceLabel,
                      style: AppTextStyles.titleMedium(context)),
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
      );
  }

  Widget _serviceIcon(ServiceListing service) {
    return CircleAvatar(
      radius: AppSpacing.avatarSizeLarge / 2,
      backgroundColor: AppColors.customerAccent.withAlpha(28),
      child: Icon(Icons.home_repair_service_rounded, color: AppColors.customerAccent, size: AppSpacing.iconSizeLarge),
    );
  }
}