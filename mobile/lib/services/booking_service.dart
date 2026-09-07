import '../models/booking_models.dart';
import 'api_client.dart';
import 'auth_service.dart';

class BookingService {
  final AuthService _authService;

  BookingService({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<Booking> createBooking({
    required int serviceId,
    required int workerId,
    required DateTime scheduledDate,
    required DateTime startTime,
    required DateTime endTime,
    required String serviceAddress,
  }) async {
    final token = await _authService.getToken();
    final response = await ApiClient.post('/bookings', {
      'service_id': serviceId,
      'worker_id': workerId,
      'scheduled_date': _date(scheduledDate),
      'start_time': _time(startTime),
      'end_time': _time(endTime),
      'service_address': serviceAddress,
    }, token: token);
    return Booking.fromJson(response);
  }

  Future<List<Booking>> getCustomerBookings() async {
    return _getList('/bookings/customer');
  }

  Future<List<Booking>> getWorkerBookings() async {
    return _getList('/bookings/worker');
  }

  Future<Booking> getBookingDetails(int bookingId) async {
    final token = await _authService.getToken();
    final response = await ApiClient.get('/bookings/$bookingId', token: token);
    return Booking.fromJson(response);
  }

  Future<Booking> updateStatus(int bookingId, BookingStatus status) async {
    final token = await _authService.getToken();
    final response = await ApiClient.patch('/bookings/$bookingId/status', {
      'status': _statusValue(status),
    }, token: token);
    return Booking.fromJson(response);
  }

  Future<List<Booking>> _getList(String path) async {
    final token = await _authService.getToken();
    final response = await ApiClient.getList(path, token: token);
    return response
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _statusValue(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.disputed:
        return 'disputed';
    }
  }
}
