class ServiceListing {
  final String name;
  final String category;
  final String description;
  final String priceLabel;
  final double rating;
  final int reviewCount;
  final String iconName;

  const ServiceListing({
    required this.name,
    required this.category,
    required this.description,
    required this.priceLabel,
    required this.rating,
    required this.reviewCount,
    required this.iconName,
  });
}