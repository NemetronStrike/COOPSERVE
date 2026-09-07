import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../navigation/app_router.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class WorkerBookingsScreen extends StatefulWidget {
  final Future<List<Booking>> Function() loadBookings;
  final Future<Booking> Function(int bookingId, BookingStatus status)
  updateStatus;

  WorkerBookingsScreen({
    super.key,
    Future<List<Booking>> Function()? loadBookings,
    Future<Booking> Function(int bookingId, BookingStatus status)? updateStatus,
  }) : loadBookings = loadBookings ?? BookingService().getWorkerBookings,
       updateStatus = updateStatus ?? _defaultUpdateStatus;

  static Future<Booking> _defaultUpdateStatus(
    int bookingId,
    BookingStatus status,
  ) {
    return BookingService().updateStatus(bookingId, status);
  }

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen> {
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;
  int? _updatingId;

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
          ? const AppLoading(message: 'Loading assigned bookings')
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _bookings.isEmpty
          ? const AppEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No assigned bookings',
              subtitle: 'New customer bookings will appear here.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: _bookings.length,
                itemBuilder: (context, index) =>
                    _bookingCard(context, _bookings[index]),
              ),
            ),
    );
  }

  Widget _bookingCard(BuildContext context, Booking booking) {
    final next = switch (booking.status) {
      BookingStatus.pending => (BookingStatus.accepted, 'Accept Booking'),
      BookingStatus.accepted => (BookingStatus.inProgress, 'Start Service'),
      BookingStatus.inProgress => (BookingStatus.completed, 'Mark Completed'),
      _ => null,
    };
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
            Text(
              booking.serviceName,
              style: AppTextStyles.titleMedium(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Customer: ${booking.customerName}'),
            Text(
              '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} at ${booking.scheduledAt.hour.toString().padLeft(2, '0')}:00',
            ),
            Text(booking.serviceAddress ?? 'Address unavailable'),
            Text('Status: ${booking.status.label}'),
            if (next != null) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: _updatingId == booking.id
                    ? null
                    : () => _update(booking, next.$1),
                child: _updatingId == booking.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(next.$2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _update(Booking booking, BookingStatus status) async {
    setState(() => _updatingId = booking.id);
    try {
      await widget.updateStatus(booking.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking marked ${status.label.toLowerCase()}.'),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _updatingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}
