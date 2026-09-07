import '../models/notification.dart';
import 'api_client.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _auth = AuthService();

  Future<List<AppNotification>> getNotifications() async {
    final response = await ApiClient.getList(
      '/notifications',
      token: await _auth.getToken(),
    );
    return response
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppNotification> markRead(int notificationId) async {
    final response = await ApiClient.patch(
      '/notifications/$notificationId/read',
      {},
      token: await _auth.getToken(),
    );
    return AppNotification.fromJson(response);
  }
}
