import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/booking_models.dart';
import '../../navigation/app_router.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class BookingScreen extends StatefulWidget {
  final BookingSelection selection;
  final Future<Booking> Function({
    required int serviceId,
    required int workerId,
    required DateTime scheduledDate,
    required DateTime startTime,
    required DateTime endTime,
    required String serviceAddress,
    bool isEmergency,
  })
  createBooking;

  const BookingScreen({
    super.key,
    required this.selection,
    Future<Booking> Function({
      required int serviceId,
      required int workerId,
      required DateTime scheduledDate,
      required DateTime startTime,
      required DateTime endTime,
      required String serviceAddress,
      bool isEmergency,
    })?
    createBooking,
  }) : createBooking = createBooking ?? _defaultCreateBooking;

  static Future<Booking> _defaultCreateBooking({
    required int serviceId,
    required int workerId,
    required DateTime scheduledDate,
    required DateTime startTime,
    required DateTime endTime,
    required String serviceAddress,
    bool isEmergency = false,
  }) {
    return BookingService().createBooking(
      serviceId: serviceId,
      workerId: workerId,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      serviceAddress: serviceAddress,
      isEmergency: isEmergency,
    );
  }

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _addressController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEmergency = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.selection.service;
    final worker = widget.selection.worker;
    return Scaffold(
      appBar: AppBar(title: const Text('Book a service')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTextStyles.titleLarge(context)),
                const SizedBox(height: AppSpacing.xs),
                Text('Worker: ${worker.name}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  service.priceLabel,
                  style: AppTextStyles.titleMedium(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Service date'),
            subtitle: Text(
              _date == null ? 'Select a date' : _formatDate(_date!),
            ),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start time'),
            subtitle: Text(
              _startTime == null ? 'Select a time' : _formatTime(_startTime!),
            ),
            trailing: const Icon(Icons.schedule_rounded),
            onTap: () => _pickTime(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End time'),
            subtitle: Text(
              _endTime == null ? 'Select a time' : _formatTime(_endTime!),
            ),
            trailing: const Icon(Icons.schedule_rounded),
            onTap: () => _pickTime(isStart: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Service address',
              hintText: 'Enter the address where service is needed',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergency Service'),
            subtitle: Text(
              _isEmergency
                  ? 'A 10% emergency surcharge applies.'
                  : 'Standard service booking',
            ),
            value: _isEmergency,
            onChanged: (value) => setState(() => _isEmergency = value),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Confirm Booking',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (selected == null) return;
    setState(() => isStart ? _startTime = selected : _endTime = selected);
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    if (_date == null || _startTime == null || _endTime == null) {
      setState(
        () => _errorMessage = 'Select a date, start time, and end time.',
      );
      return;
    }
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _errorMessage = 'End time must be after start time.');
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Enter a service address.');
      return;
    }
    final now = DateTime.now();
    final start = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    if (!start.isAfter(now)) {
      setState(() => _errorMessage = 'Choose a future date and time.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final booking = await widget.createBooking(
        serviceId: widget.selection.service.id,
        workerId: widget.selection.worker.id,
        scheduledDate: _date!,
        startTime: start,
        endTime: DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _endTime!.hour,
          _endTime!.minute,
        ),
        serviceAddress: address,
        isEmergency: _isEmergency,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRouter.payment,
        arguments: booking,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  String _formatTime(TimeOfDay value) => value.format(context);
}
