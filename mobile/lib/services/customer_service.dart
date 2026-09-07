import '../models/service_listing.dart';

/// Provides customer-facing catalog data until the service catalog API exists.
class CustomerService {
  Future<List<ServiceListing>> getFeaturedServices() async {
    return const [
      ServiceListing(
        name: 'Home cleaning',
        category: 'Cleaning',
        description: 'Trusted help for a fresh, comfortable home.',
        priceLabel: 'From Rs. 499',
        rating: 4.8,
        reviewCount: 124,
        iconName: 'cleaning',
      ),
      ServiceListing(
        name: 'Electrician',
        category: 'Repairs',
        description: 'Skilled support for everyday electrical needs.',
        priceLabel: 'From Rs. 299',
        rating: 4.7,
        reviewCount: 98,
        iconName: 'electrical',
      ),
      ServiceListing(
        name: 'Plumbing repair',
        category: 'Repairs',
        description: 'Quick, dependable fixes from verified workers.',
        priceLabel: 'From Rs. 349',
        rating: 4.6,
        reviewCount: 76,
        iconName: 'plumbing',
      ),
      ServiceListing(
        name: 'Appliance service',
        category: 'Maintenance',
        description: 'Care for the appliances your household relies on.',
        priceLabel: 'From Rs. 399',
        rating: 4.5,
        reviewCount: 64,
        iconName: 'appliance',
      ),
    ];
  }
}