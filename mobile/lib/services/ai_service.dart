import 'api_client.dart';
import '../models/worker_profile.dart';
import 'auth_service.dart';

class AIService {
  final _authService = AuthService();

  Future<Map<String, dynamic>> searchServices(String query) async {
    final token = await _authService.getToken();
    final response = await ApiClient.post('/ai/service-search', {
      'query': query,
    }, token: token);
    return response;
  }

  Future<List<AIWorkerMatch>> matchWorkers(int serviceId, {String urgency = 'normal', String? notes}) async {
    final token = await _authService.getToken();
    final response = await ApiClient.post('/ai/match-workers', {
      'service_id': serviceId,
      'urgency': urgency,
      'notes': notes,
    }, token: token);
    
    return (response['matches'] as List)
        .map((json) => AIWorkerMatch.fromJson(json))
        .toList();
  }
}
