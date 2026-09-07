import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: Colors.green),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Booking created',
            style: AppTextStyles.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(child: _summary(context)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'View My Bookings',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/customer/bookings'),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking #${booking.id}',
          style: AppTextStyles.titleLarge(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(booking.serviceName),
        Text('Worker: ${booking.workerName ?? 'Assigned worker'}'),
        Text(
          'Date: ${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}',
        ),
        Text('Address: ${booking.serviceAddress ?? 'Not provided'}'),
        Text('Amount: Rs. ${booking.amount.toStringAsFixed(0)}'),
        Text('Status: ${booking.status.label}'),
      ],
    );
  }
}
