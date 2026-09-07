import '../models/admin_models.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _auth = AuthService();

  Future<AdminDashboardStats> getDashboard() async {
    final response = await ApiClient.get(
      '/admin/dashboard',
      token: await _auth.getToken(),
    );
    return AdminDashboardStats.fromJson(response);
  }

  Future<List<AdminWorker>> getWorkers({String? status}) async {
    final response = await ApiClient.getList(
      '/admin/workers',
      token: await _auth.getToken(),
      queryParameters: {
        if (status != null && status != 'all') 'verification_status': status,
      },
    );
    return response
        .map((item) => AdminWorker.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminWorker> updateVerification(int workerId, String status) async {
    final response = await ApiClient.patch(
      '/admin/workers/$workerId/verification',
      {'status': status},
      token: await _auth.getToken(),
    );
    return AdminWorker.fromJson(response);
  }
}
