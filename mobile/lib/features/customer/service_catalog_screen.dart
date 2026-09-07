import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/service_listing.dart';
import '../../navigation/app_router.dart';
import '../../services/customer_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class ServiceCatalogScreen extends StatefulWidget {
  final Future<List<ServiceListing>> Function({String? search, String? category})
      loadServices;
  final Future<Map<String, dynamic>> Function(String query) aiSearch;

  ServiceCatalogScreen({
    super.key,
    Future<List<ServiceListing>> Function({String? search, String? category})?
        loadServices,
    Future<Map<String, dynamic>> Function(String query)? aiSearch,
  }) : loadServices = loadServices ?? CustomerService().getAllServices,
       aiSearch = aiSearch ?? AIService().searchServices;

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  final _searchController = TextEditingController();
  List<ServiceListing> _services = const [];
  List<String> _categories = const ['All'];
  bool _isLoading = true;
  String? _errorMessage;
  String? _aiInterpretation;
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

  Future<void> _loadServices({String? search, String? category}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiInterpretation = null;
    });
    try {
      final services = await widget.loadServices(
        search: search,
        category: category,
      );
      if (!mounted) return;
      setState(() {
        _services = services;
        if (search == null && category == null) {
          _categories = [
            'All',
            ...services.map((service) => service.category).toSet(),
          ];
        }
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

  Future<void> _performAiSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadServices();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiInterpretation = null;
    });

    try {
      final result = await widget.aiSearch(query);
      if (!mounted) return;

      final servicesJson = result['services'] as List;
      final servicesList = servicesJson.map((json) => ServiceListing.fromJson(json)).toList();

      setState(() {
        _services = servicesList;
        _aiInterpretation = result['interpretation'];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fallback to normal search
      _loadServices(search: query, category: _selectedCategory == 'All' ? null : _selectedCategory);
    }
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
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _performAiSearch(),
            decoration: InputDecoration(
              hintText: 'Describe what you need in natural language...',
              prefixIcon: const Icon(Icons.auto_awesome), // AI icon
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: _performAiSearch,
              ),
            ),
          ),
          if (_aiInterpretation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI: $_aiInterpretation',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.brandDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Categories', style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: AppSpacing.sm),
          _buildCategories(),
          const SizedBox(height: AppSpacing.lg),
          if (_services.isEmpty)
            const SizedBox(
              height: 300,
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No services found',
                subtitle: 'Try a different search or category.',
              ),
            )
          else
            ..._services.map((service) => _buildServiceCard(service)),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: category == _selectedCategory,
            onSelected: (_) => _onCategorySelected(category),
          );
        },
      ),
    );
  }

  void _onSearchChanged(String value) {
    _loadServices(
      search: value.trim().isEmpty ? null : value.trim(),
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _loadServices(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      category: category == 'All' ? null : category,
    );
  }

  Widget _buildServiceCard(ServiceListing service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.serviceDetails,
          arguments: service.id,
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
