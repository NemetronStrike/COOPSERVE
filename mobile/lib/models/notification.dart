class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? relatedBookingId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.relatedBookingId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        type: json['type'] as String,
        relatedBookingId: json['related_booking_id'] as int?,
        isRead: json['is_read'] as bool,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );
}
