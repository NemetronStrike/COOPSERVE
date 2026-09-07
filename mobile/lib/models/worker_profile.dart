class WorkerProfile {
  final int id;
  final int userId;
  final String name;
  final String? bio;
  final List<String> skills;
  final int? experienceYears;
  final double rating;
  final int completedJobs;
  final bool isAvailable;
  final bool isVerified;

  const WorkerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.bio,
    required this.skills,
    required this.experienceYears,
    required this.rating,
    required this.completedJobs,
    required this.isAvailable,
    required this.isVerified,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((skill) => skill.toString())
          .toList(),
      experienceYears: json['experience_years'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}