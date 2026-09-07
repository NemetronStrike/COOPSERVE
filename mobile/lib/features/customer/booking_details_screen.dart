import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;
  final Future<Booking> Function(int id) loadBooking;

  BookingDetailsScreen({
    super.key,
    required this.bookingId,
    Future<Booking> Function(int id)? loadBooking,
  }) : loadBooking = loadBooking ?? BookingService().getBookingDetails;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Booking? _booking;
  String? _errorMessage;

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
              if (booking.createdAt != null)
                Text(
                  'Created: ${booking.createdAt!.day}/${booking.createdAt!.month}/${booking.createdAt!.year}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
