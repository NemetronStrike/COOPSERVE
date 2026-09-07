class ServiceListing {
  final int id;
  final String name;
  final String category;
  final String description;
  final String priceLabel;
  final double rating;
  final int reviewCount;
  final String iconName;

  const ServiceListing({
    this.id = 0,
    required this.name,
    required this.category,
    required this.description,
    required this.priceLabel,
    required this.rating,
    required this.reviewCount,
    required this.iconName,
  });

  factory ServiceListing.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['base_price'];
    final basePrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    return ServiceListing(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      priceLabel: 'From Rs. ${basePrice.toStringAsFixed(0)}',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      iconName: _iconNameForCategory(json['category'] as String),
    );
  }

  static String _iconNameForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return 'cleaning';
      case 'repairs':
        return 'electrical';
      case 'maintenance':
        return 'appliance';
      default:
        return 'home';
    }
  }
}