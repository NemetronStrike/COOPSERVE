import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/transaction_models.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class InvoiceScreen extends StatefulWidget {
  final int bookingId;
  final Future<InvoiceRecord> Function(int bookingId) loadInvoice;

  InvoiceScreen({
    super.key,
    required this.bookingId,
    Future<InvoiceRecord> Function(int bookingId)? loadInvoice,
  }) : loadInvoice = loadInvoice ?? BookingService().getInvoice;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  InvoiceRecord? _invoice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invoice = await widget.loadInvoice(widget.bookingId);
      if (!mounted) return;
      setState(() => _invoice = invoice);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: _invoice == null && _error == null
          ? const AppLoading(message: 'Loading invoice')
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _buildInvoice(context, _invoice!),
    );
  }

  Widget _buildInvoice(BuildContext context, InvoiceRecord invoice) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COOPSERVE', style: AppTextStyles.headlineSmall(context)),
              Text(
                'Invoice ${invoice.invoiceNumber}',
                style: AppTextStyles.titleMedium(context),
              ),
              const Divider(height: AppSpacing.lg),
              Text('Booking #${invoice.bookingId}'),
              Text('Customer: ${invoice.customerName}'),
              Text('Worker: ${invoice.workerName ?? 'Assigned worker'}'),
              Text('Service: ${invoice.serviceName}'),
              Text('Address: ${invoice.serviceAddress ?? 'Not provided'}'),
              const SizedBox(height: AppSpacing.md),
              Text('Subtotal: Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
              Text('Tax: Rs. ${invoice.tax.toStringAsFixed(0)}'),
              Text(
                'Total: Rs. ${invoice.total.toStringAsFixed(0)}',
                style: AppTextStyles.titleLarge(context),
              ),
              Text('Payment: ${invoice.paymentStatus}'),
              Text('Transaction: ${invoice.transactionReference}'),
            ],
          ),
        ),
      ],
    );
  }
}
