import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../models/service_listing.dart';
import '../../models/worker_profile.dart';
import '../../navigation/app_router.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final int workerId;
  final WorkerProfile? initialWorker;
  final ServiceListing? service;
  final Future<WorkerProfile> Function(int workerId) loadWorker;

  WorkerDetailsScreen({
    super.key,
    required this.workerId,
    this.initialWorker,
    this.service,
    Future<WorkerProfile> Function(int workerId)? loadWorker,
  }) : loadWorker = loadWorker ?? CustomerService().getWorkerDetails;

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  WorkerProfile? _worker;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialWorker != null) {
      _worker = widget.initialWorker;
    } else {
      _loadWorker();
    }
  }

  Future<void> _loadWorker() async {
    try {
      final worker = await widget.loadWorker(widget.workerId);
      if (!mounted) return;
      setState(() => _worker = worker);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'We could not load this worker.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker details')),
      body: _worker == null && _errorMessage == null
          ? const AppLoading(message: 'Loading worker details')
          : _errorMessage != null
          ? AppErrorState(message: _errorMessage!, onRetry: _loadWorker)
          : _buildDetails(context, _worker!),
    );
  }

  Widget _buildDetails(BuildContext context, WorkerProfile worker) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarSizeLarge / 2,
                backgroundColor: AppColors.customerAccent.withAlpha(28),
                child: Icon(
                  Icons.person_rounded,
                  size: AppSpacing.iconSizeLarge,
                  color: AppColors.customerAccent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(worker.name, style: AppTextStyles.headlineSmall(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(worker.bio ?? 'Cooperative service professional.'),
              const SizedBox(height: AppSpacing.md),
              Text(
                worker.skills.join(' • '),
                style: AppTextStyles.labelLarge(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${worker.rating.toStringAsFixed(1)} rating • '
                '${worker.completedJobs} completed jobs',
              ),
              if (worker.experienceYears != null)
                Text('${worker.experienceYears} years of experience'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          worker.isAvailable
              ? 'Available for service requests'
              : 'Currently unavailable',
          style: AppTextStyles.titleMedium(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          worker.isVerified
              ? 'Verified cooperative worker'
              : 'Verification information unavailable',
        ),
        if (widget.service != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Book Now',
            icon: Icons.calendar_month_rounded,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.createBooking,
              arguments: BookingSelection(
                service: widget.service!,
                worker: worker,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
