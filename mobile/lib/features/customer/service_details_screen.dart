import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/service_listing.dart';
import '../../models/booking_models.dart';
import '../../models/worker_profile.dart';
import '../../navigation/app_router.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  final Future<ServiceListing> Function(int serviceId) loadService;
  final Future<List<WorkerProfile>> Function(int serviceId) loadWorkers;

  ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    Future<ServiceListing> Function(int serviceId)? loadService,
    Future<List<WorkerProfile>> Function(int serviceId)? loadWorkers,
  }) : loadService = loadService ?? CustomerService().getServiceDetails,
       loadWorkers = loadWorkers ?? _defaultLoadWorkers;

  static Future<List<WorkerProfile>> _defaultLoadWorkers(int serviceId) {
    return CustomerService().getWorkers(serviceId: serviceId);
  }

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  ServiceListing? _service;
  List<WorkerProfile> _workers = const [];
  bool _workersLoading = true;
  String? _workersError;
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
      await _loadWorkers(service.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'We could not load this service.');
    }
  }

  Future<void> _loadWorkers(int serviceId) async {
    setState(() {
      _workersLoading = true;
      _workersError = null;
    });
    try {
      final workers = await widget.loadWorkers(serviceId);
      if (!mounted) return;
      setState(() {
        _workers = workers;
        _workersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _workersLoading = false;
        _workersError = 'We could not load available workers.';
      });
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
              Text(service.name, style: AppTextStyles.headlineSmall(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(service.category, style: AppTextStyles.labelLarge(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                service.description,
                style: AppTextStyles.bodyLarge(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${service.rating} (${service.reviewCount} reviews)'),
                  const Spacer(),
                  Text(
                    service.priceLabel,
                    style: AppTextStyles.titleMedium(context),
                  ),
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
        _buildAvailableWorkers(context, service.id),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Continue to booking',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking will be available soon.')),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableWorkers(BuildContext context, int serviceId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Workers', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.sm),
        if (_workersLoading)
          const AppLoading(message: 'Finding available workers')
        else if (_workersError != null)
          AppErrorState(
            message: _workersError!,
            retryLabel: 'Retry workers',
            onRetry: () => _loadWorkers(serviceId),
          )
        else if (_workers.isEmpty)
          const AppCard(
            child: Text(
              'No verified workers are available for this service yet.',
            ),
          )
        else
          ..._workers.map((worker) => _buildWorkerCard(context, worker)),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, WorkerProfile worker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.workerDetails,
          arguments: BookingSelection(service: _service!, worker: worker),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.customerAccent.withAlpha(28),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.customerAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker.name,
                          style: AppTextStyles.titleMedium(context),
                        ),
                      ),
                      if (worker.isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text('★ ${worker.rating.toStringAsFixed(1)}'),
                      Text('${worker.completedJobs} jobs'),
                      Text(worker.isAvailable ? 'Available' : 'Unavailable'),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.workerDetails,
                        arguments: BookingSelection(
                          service: _service!,
                          worker: worker,
                        ),
                      ),
                      child: const Text('Select Worker'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _serviceIcon(ServiceListing service) {
    return CircleAvatar(
      radius: AppSpacing.avatarSizeLarge / 2,
      backgroundColor: AppColors.customerAccent.withAlpha(28),
      child: Icon(
        Icons.home_repair_service_rounded,
        color: AppColors.customerAccent,
        size: AppSpacing.iconSizeLarge,
      ),
    );
  }
}
