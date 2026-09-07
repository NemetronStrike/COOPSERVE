import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../navigation/app_router.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final Future<List<Booking>> Function() loadBookings;

  CustomerBookingsScreen({
    super.key,
    Future<List<Booking>> Function()? loadBookings,
  }) : loadBookings = loadBookings ?? BookingService().getCustomerBookings;

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await widget.loadBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: _loading
          ? const AppLoading(message: 'Loading bookings')
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: _bookings.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        AppEmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'No bookings yet',
                          subtitle: 'Your confirmed services will appear here.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) =>
                          _bookingCard(context, _bookings[index]),
                    ),
            ),
    );
  }

  Widget _bookingCard(BuildContext context, Booking booking) {
    final statusColor = booking.status == BookingStatus.completed
        ? AppColors.success
        : booking.status == BookingStatus.cancelled
        ? AppColors.error
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.bookingDetails,
          arguments: booking.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: AppTextStyles.titleMedium(context),
                  ),
                ),
                Chip(
                  label: Text(booking.status.label),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Worker: ${booking.workerName ?? 'Assigned worker'}'),
            Text(
              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} at ${booking.scheduledAt.hour.toString().padLeft(2, '0')}:00',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rs. ${booking.amount.toStringAsFixed(0)}',
              style: AppTextStyles.labelLarge(context),
            ),
          ],
        ),
      ),
    );
  }
}
