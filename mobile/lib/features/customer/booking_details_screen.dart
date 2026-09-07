import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../models/transaction_models.dart';
import '../../navigation/app_router.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;
  final Future<Booking> Function(int id) loadBooking;
  final Future<RatingRecord?> Function(int id) loadRating;

  BookingDetailsScreen({
    super.key,
    required this.bookingId,
    Future<Booking> Function(int id)? loadBooking,
    Future<RatingRecord?> Function(int id)? loadRating,
  }) : loadBooking = loadBooking ?? BookingService().getBookingDetails,
       loadRating = loadRating ?? BookingService().getRating;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Booking? _booking;
  String? _errorMessage;
  RatingRecord? _rating;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await widget.loadBooking(widget.bookingId);
      if (!mounted) return;
      setState(() => _booking = booking);
      if (booking.status == BookingStatus.completed) {
        final rating = await widget.loadRating(booking.id);
        if (mounted) setState(() => _rating = rating);
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: _booking == null && _errorMessage == null
          ? const AppLoading(message: 'Loading booking')
          : _errorMessage != null
          ? AppErrorState(message: _errorMessage!, onRetry: _loadBooking)
          : _buildDetails(context, _booking!),
    );
  }

  Widget _buildDetails(BuildContext context, Booking booking) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking #${booking.id}',
                style: AppTextStyles.titleLarge(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Service: ${booking.serviceName}'),
              Text('Worker: ${booking.workerName ?? 'Assigned worker'}'),
              Text(
                'Date: ${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}',
              ),
              Text(
                'Time: ${booking.scheduledAt.hour.toString().padLeft(2, '0')}:00',
              ),
              Text('Address: ${booking.serviceAddress ?? 'Not provided'}'),
              Text('Amount: Rs. ${booking.amount.toStringAsFixed(0)}'),
              Text('Status: ${booking.status.label}'),
              Text('Payment: ${booking.paymentStatus ?? 'Not paid'}'),
              if (booking.transactionReference != null)
                Text('Transaction: ${booking.transactionReference}'),
              if (booking.createdAt != null)
                Text(
                  'Created: ${booking.createdAt!.day}/${booking.createdAt!.month}/${booking.createdAt!.year}',
                ),
            ],
          ),
        ),
        if (booking.paymentId == null &&
            booking.status != BookingStatus.cancelled) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Pay Now',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.payment,
              arguments: booking,
            ),
          ),
        ],
        if (booking.paymentId != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButtonOutlined(
            label: 'View Invoice',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.invoice,
              arguments: booking.id,
            ),
          ),
        ],
        if (booking.status == BookingStatus.completed) ...[
          const SizedBox(height: AppSpacing.md),
          if (_rating == null)
            AppButton(
              label: 'Rate Worker',
              onPressed: () async {
                final submitted = await Navigator.pushNamed(
                  context,
                  AppRouter.rating,
                  arguments: booking,
                );
                if (submitted == true) _loadBooking();
              },
            )
          else
            AppCard(
              child: Text(
                'Your rating: ${'★' * _rating!.rating}\n${_rating!.review ?? ''}',
              ),
            ),
        ],
      ],
    );
  }
}
