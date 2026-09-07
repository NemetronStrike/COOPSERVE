import 'service_listing.dart';
import 'worker_profile.dart';

enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  confirmed,
  disputed,
}

BookingStatus bookingStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'accepted':
      return BookingStatus.accepted;
    case 'in_progress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'disputed':
      return BookingStatus.disputed;
    default:
      return BookingStatus.pending;
  }
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.inProgress:
        return 'In progress';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }
}

class Booking {
  final int id;
  final int customerId;
  final int? workerId;
  final int serviceId;
  final DateTime scheduledAt;
  final DateTime? scheduledEndAt;
  final String? serviceAddress;
  final double amount;
  final BookingStatus status;
  final DateTime? createdAt;
  final String customerName;
  final String? workerName;
  final String serviceName;
  final int? paymentId;
  final String? paymentStatus;
  final String? transactionReference;
  final bool isEmergency;

  const Booking({
    required this.id,
    required this.customerId,
    required this.workerId,
    required this.serviceId,
    required this.scheduledAt,
    required this.scheduledEndAt,
    required this.serviceAddress,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.workerName,
    required this.serviceName,
    this.paymentId,
    this.paymentStatus,
    this.transactionReference,
    this.isEmergency = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0;
    return Booking(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      workerId: json['worker_id'] as int?,
      serviceId: json['service_id'] as int,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      scheduledEndAt: json['scheduled_end_at'] == null
          ? null
          : DateTime.parse(json['scheduled_end_at'] as String),
      serviceAddress: json['service_address'] as String?,
      amount: amount,
      status: bookingStatusFromString(json['status'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String? ?? 'Customer',
      workerName: json['worker_name'] as String?,
      serviceName: json['service_name'] as String? ?? 'Service',
      paymentId: json['payment_id'] as int?,
      paymentStatus: json['payment_status'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      isEmergency: json['is_emergency'] as bool? ?? false,
    );
  }
}

class BookingSelection {
  final ServiceListing service;
  final WorkerProfile worker;

  const BookingSelection({required this.service, required this.worker});
}
