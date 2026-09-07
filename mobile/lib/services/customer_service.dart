import '../models/service_listing.dart';
import '../models/worker_profile.dart';
import 'api_client.dart';

/// Retrieves customer-facing catalog data through the FastAPI service layer.
class CustomerService {
  Future<List<ServiceListing>> getAllServices({
    String? search,
    String? category,
  }) async {
    final response = await ApiClient.getList(
      '/services',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search,
        if (category != null && category.trim().isNotEmpty) 'category': category,
      },
    );
    return response
        .map((item) => ServiceListing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceListing>> getFeaturedServices() async {
    final services = await getAllServices();
    return services.take(4).toList();
  }

  Future<ServiceListing> getServiceDetails(int serviceId) async {
    final response = await ApiClient.get('/services/$serviceId');
    return ServiceListing.fromJson(response);
  }

  Future<List<WorkerProfile>> getWorkers({int? serviceId}) async {
    final workers = await ApiClient.getList(
      '/workers',
      queryParameters: {
        if (serviceId != null) 'service_id': serviceId.toString(),
      },
    );
    return workers
        .map((item) => WorkerProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkerProfile> getWorkerDetails(int workerId) async {
    final response = await ApiClient.get('/workers/$workerId');
    return WorkerProfile.fromJson(response);
  }
}