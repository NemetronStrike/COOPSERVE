import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../models/transaction_models.dart';
import '../../models/payment_confirmation.dart';
import '../../navigation/app_router.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final Future<PaymentRecord> Function(int bookingId) pay;

  const PaymentScreen({
    super.key,
    required this.booking,
    Future<PaymentRecord> Function(int bookingId)? pay,
  }) : pay = pay ?? _defaultPay;

  static Future<PaymentRecord> _defaultPay(int bookingId) =>
      BookingService().payForBooking(bookingId);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  PaymentRecord? _payment;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Payment')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Payment',
                  style: AppTextStyles.headlineSmall(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Sandbox transaction. No real money will be charged.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  booking.serviceName,
                  style: AppTextStyles.titleMedium(context),
                ),
                Text('Worker: ${booking.workerName ?? 'Assigned worker'}'),
                Text('Address: ${booking.serviceAddress ?? 'Not provided'}'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Amount: Rs. ${booking.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.titleLarge(context),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorState(message: _error!),
          ],
          if (_payment != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Successful'),
                  Text('Transaction: ${_payment!.transactionReference}'),
                  Text('Booking #${_payment!.bookingId}'),
                  Text('Amount: Rs. ${_payment!.amount.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Continue to Confirmation',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRouter.bookingConfirmation,
                arguments: PaymentConfirmation(
                  booking: booking,
                  payment: _payment!,
                ),
              ),
            ),
          ] else
            AppButton(label: 'Pay Now', isLoading: _loading, onPressed: _pay),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payment = await widget.pay(widget.booking.id);
      if (!mounted) return;
      setState(() {
        _payment = payment;
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
}
