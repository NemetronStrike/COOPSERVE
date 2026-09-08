class AdminDashboardStats {
  final int totalCustomers;
  final int totalWorkers;
  final int verifiedWorkers;
  final int pendingWorkerVerifications;
  final int totalBookings;
  final int pendingBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int totalPayments;

  const AdminDashboardStats({
    required this.totalCustomers,
    required this.totalWorkers,
    required this.verifiedWorkers,
    required this.pendingWorkerVerifications,
    required this.totalBookings,
    required this.pendingBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalPayments,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        totalCustomers: json['total_customers'] as int,
        totalWorkers: json['total_workers'] as int,
        verifiedWorkers: json['verified_workers'] as int,
        pendingWorkerVerifications: json['pending_worker_verifications'] as int,
        totalBookings: json['total_bookings'] as int,
        pendingBookings: json['pending_bookings'] as int,
        completedBookings: json['completed_bookings'] as int,
        cancelledBookings: json['cancelled_bookings'] as int,
        totalPayments: json['total_payments'] as int,
      );
}

class AdminWorker {
  final int id;
  final String name;
  final List<String> skills;
  final int? experienceYears;
  final double rating;
  final int totalJobs;
  final bool isAvailable;
  final String verificationStatus;

  const AdminWorker({
    required this.id,
    required this.name,
    required this.skills,
    required this.experienceYears,
    required this.rating,
    required this.totalJobs,
    required this.isAvailable,
    required this.verificationStatus,
  });

  factory AdminWorker.fromJson(Map<String, dynamic> json) => AdminWorker(
    id: json['id'] as int,
    name: json['name'] as String,
    skills: (json['skills'] as List<dynamic>)
        .map((item) => item.toString())
        .toList(),
    experienceYears: json['experience_years'] as int?,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    totalJobs: json['total_jobs'] as int? ?? 0,
    isAvailable: json['is_available'] as bool? ?? true,
    verificationStatus: json['verification_status'] as String,
  );
}

class DailyForecast {
  final DateTime date;
  final double predictedDemand;
  final double availableSupply;
  final String status;

  const DailyForecast({
    required this.date,
    required this.predictedDemand,
    required this.availableSupply,
    required this.status,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date'] as String),
        predictedDemand: (json['predicted_demand'] as num).toDouble(),
        availableSupply: (json['available_supply'] as num).toDouble(),
        status: json['status'] as String,
      );
}

class CategoryForecast {
  final String category;
  final List<DailyForecast> dailyForecasts;

  const CategoryForecast({
    required this.category,
    required this.dailyForecasts,
  });

  factory CategoryForecast.fromJson(Map<String, dynamic> json) =>
      CategoryForecast(
        category: json['category'] as String,
        dailyForecasts: (json['daily_forecasts'] as List<dynamic>)
            .map((item) => DailyForecast.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class DemandForecastResponse {
  final DateTime generatedAt;
  final List<CategoryForecast> forecasts;

  const DemandForecastResponse({
    required this.generatedAt,
    required this.forecasts,
  });

  factory DemandForecastResponse.fromJson(Map<String, dynamic> json) =>
      DemandForecastResponse(
        generatedAt: DateTime.parse(json['generated_at'] as String),
        forecasts: (json['forecasts'] as List<dynamic>)
            .map((item) => CategoryForecast.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
