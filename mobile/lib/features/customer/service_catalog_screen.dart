import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/service_listing.dart';
import '../../navigation/app_router.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class ServiceCatalogScreen extends StatefulWidget {
  final Future<List<ServiceListing>> Function() loadServices;

  ServiceCatalogScreen({
    super.key,
    Future<List<ServiceListing>> Function()? loadServices,
  }) : loadServices = loadServices ?? CustomerService().getAllServices;

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  final _searchController = TextEditingController();
  List<ServiceListing> _services = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final services = await widget.loadServices();
      if (!mounted) return;
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'We could not load services right now.';
      });
    }
  }

  List<ServiceListing> get _visibleServices {
    final query = _searchController.text.trim().toLowerCase();
    return _services.where((service) {
      final matchesCategory =
          _selectedCategory == 'All' || service.category == _selectedCategory;
      final searchableText =
          '${service.name} ${service.description}'.toLowerCase();
      return matchesCategory &&
          (query.isEmpty || searchableText.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: _isLoading
          ? const AppLoading(message: 'Loading services')
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadServices)
              : _buildCatalog(context),
    );
  }

  Widget _buildCatalog(BuildContext context) {
    final categories = <String>{
      'All',
      ..._services.map((service) => service.category),
    }.toList();

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          Text('Find a service', style: AppTextStyles.headlineSmall(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by name or description',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Categories', style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.sm),
          _buildCategories(categories),
          const SizedBox(height: AppSpacing.lg),
          if (_visibleServices.isEmpty)
            const SizedBox(
              height: 300,
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No services found',
                subtitle: 'Try a different search or category.',
              ),
            )
          else
            ..._visibleServices.map((service) => _buildServiceCard(service)),
        ],
      ),
    );
  }

  Widget _buildCategories(List<String> categories) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: category == _selectedCategory,
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceListing service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.serviceDetails,
          arguments: service,
        ),
        child: Row(
          children: [
            _serviceIcon(service.iconName),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: AppTextStyles.titleMedium(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(service.category, style: AppTextStyles.labelSmall(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(service.description, style: AppTextStyles.bodySmall(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.xs),
                      Text('${service.rating} (${service.reviewCount})', style: AppTextStyles.labelSmall(context)),
                      const Spacer(),
                      Text(service.priceLabel, style: AppTextStyles.labelLarge(context)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _serviceIcon(String iconName) {
    final icon = switch (iconName) {
      'cleaning' => Icons.cleaning_services_rounded,
      'electrical' => Icons.electrical_services_rounded,
      'plumbing' => Icons.plumbing_rounded,
      'garden' => Icons.yard_rounded,
      _ => Icons.home_repair_service_rounded,
    };
    return CircleAvatar(
      radius: AppSpacing.avatarSize / 2,
      backgroundColor: AppColors.customerAccent.withAlpha(28),
      child: Icon(icon, color: AppColors.customerAccent),
    );
  }
}