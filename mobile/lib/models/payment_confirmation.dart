import 'booking_models.dart';
import 'transaction_models.dart';

class PaymentConfirmation {
  final Booking booking;
  final PaymentRecord payment;

  const PaymentConfirmation({required this.booking, required this.payment});
}
