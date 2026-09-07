class PaymentRecord {
  final int id;
  final int bookingId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String transactionReference;
  final DateTime? createdAt;

  const PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return PaymentRecord(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'mock',
      status: json['status'] as String? ?? 'success',
      transactionReference: json['transaction_reference'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

class InvoiceRecord {
  final int id;
  final String invoiceNumber;
  final int bookingId;
  final String customerName;
  final String? workerName;
  final String serviceName;
  final DateTime scheduledAt;
  final String? serviceAddress;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentStatus;
  final String transactionReference;
  final DateTime? issuedAt;

  const InvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    required this.bookingId,
    required this.customerName,
    required this.workerName,
    required this.serviceName,
    required this.scheduledAt,
    required this.serviceAddress,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentStatus,
    required this.transactionReference,
    required this.issuedAt,
  });

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    double money(String key) {
      final raw = json[key];
      return raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
    }

    return InvoiceRecord(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      bookingId: json['booking_id'] as int,
      customerName: json['customer_name'] as String,
      workerName: json['worker_name'] as String?,
      serviceName: json['service_name'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      serviceAddress: json['service_address'] as String?,
      subtotal: money('subtotal'),
      tax: money('tax'),
      total: money('total'),
      paymentStatus: json['payment_status'] as String,
      transactionReference: json['transaction_reference'] as String,
      issuedAt: json['issued_at'] == null
          ? null
          : DateTime.parse(json['issued_at'] as String),
    );
  }
}

class RatingRecord {
  final int id;
  final int bookingId;
  final int rating;
  final String? review;
  final DateTime? createdAt;

  const RatingRecord({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory RatingRecord.fromJson(Map<String, dynamic> json) => RatingRecord(
    id: json['id'] as int,
    bookingId: json['booking_id'] as int,
    rating: json['rating'] as int,
    review: json['review'] as String?,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );
}
