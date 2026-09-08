class Complaint {
  final int id;
  final int complainantId;
  final int? bookingId;
  final String category;
  final String description;
  final String status;
  final String? resolutionNotes;
  final int? assignedAdminId;
  final String? severity;
  final String? urgency;
  final String? summary;
  final String? suggestedAction;
  final String? classificationSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.complainantId,
    this.bookingId,
    required this.category,
    required this.description,
    required this.status,
    this.resolutionNotes,
    this.assignedAdminId,
    this.severity,
    this.urgency,
    this.summary,
    this.suggestedAction,
    this.classificationSource,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      complainantId: json['complainant_id'],
      bookingId: json['booking_id'],
      category: json['category'],
      description: json['description'],
      status: json['status'],
      resolutionNotes: json['resolution_notes'],
      assignedAdminId: json['assigned_admin_id'],
      severity: json['severity'],
      urgency: json['urgency'],
      summary: json['summary'],
      suggestedAction: json['suggested_action'],
      classificationSource: json['classification_source'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
