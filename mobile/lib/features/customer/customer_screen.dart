import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/auth_models.dart';
import '../../models/service_listing.dart';
import '../../navigation/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _authService = AuthService();
  final _customerService = CustomerService();
  final _searchController = TextEditingController();

  UserProfile? _profile;
  List<ServiceListing> _services = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _authService.getCurrentUser(),
        _customerService.getFeaturedServices(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile?;
        _services = results[1] as List<ServiceListing>;
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
      final matchesSearch = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COOPSERVE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoading(message: 'Preparing your services')
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadDashboard)
              : _buildDashboard(context),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final categories = <String>{
      'All',
      ..._services.map((service) => service.category),
    }.toList();

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          _buildWelcome(context),
          const SizedBox(height: AppSpacing.lg),
          _buildSearchField(),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader(context, 'Browse by category'),
          const SizedBox(height: AppSpacing.sm),
          _buildCategories(categories),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader(
            context,
            'Popular services',
            actionLabel: 'View all',
            onAction: () => Navigator.pushNamed(context, AppRouter.serviceCatalog),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_visibleServices.isEmpty)
            const AppCard(child: Text('No services match your search yet.'))
          else
            ..._visibleServices.map((service) => _buildServiceCard(service)),
          const SizedBox(height: AppSpacing.lg),
          _buildBookingsCard(context),
          const SizedBox(height: AppSpacing.sm),
          _buildComplaintsCard(context),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final name = _profile?.fullName.trim();
    final greeting = name == null || name.isEmpty ? 'Welcome' : 'Welcome, $name';
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.avatarSize / 2,
            backgroundColor: AppColors.customerAccent.withAlpha(28),
            child: Icon(Icons.person_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTextStyles.titleLarge(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Find trusted cooperative services near you.',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'What service do you need?',
        prefixIcon: Icon(Icons.search_rounded),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.titleLarge(context))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }

  Widget _buildServiceCard(ServiceListing service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () {},
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
      _ => Icons.home_repair_service_rounded,
    };
    return CircleAvatar(
      radius: AppSpacing.avatarSize / 2,
      backgroundColor: AppColors.customerAccent.withAlpha(28),
      child: Icon(icon, color: AppColors.customerAccent),
    );
  }

  Widget _buildBookingsCard(BuildContext context) {
    return AppCardOutlined(
      onTap: () => Navigator.pushNamed(context, AppRouter.customerBookings),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My bookings', style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text('Track your upcoming services', style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Widget _buildComplaintsCard(BuildContext context) {
    return AppCardOutlined(
      onTap: () => Navigator.pushNamed(context, AppRouter.customerComplaints),
      child: Row(
        children: [
          Icon(Icons.report_problem_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My complaints', style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.xs),
                Text('View and track your complaints', style: AppTextStyles.bodySmall(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.roleSelection,
        (_) => false,
      );
    }
  }
}
