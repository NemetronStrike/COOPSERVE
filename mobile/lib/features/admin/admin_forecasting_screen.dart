import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_spacing.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_card.dart';

class AdminForecastingScreen extends StatefulWidget {
  const AdminForecastingScreen({super.key});

  @override
  State<AdminForecastingScreen> createState() => _AdminForecastingScreenState();
}

class _AdminForecastingScreenState extends State<AdminForecastingScreen> {
  DemandForecastResponse? _response;
  String? _error;
  final _dateFormat = DateFormat('EEE, MMM d');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await AdminService().getForecasting();
      if (mounted) setState(() => _response = res);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demand Forecasting'),
      ),
      body: _response == null && _error == null
          ? const AppLoading(message: 'Analyzing demand & supply...')
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _buildDashboard(context, _response!),
    );
  }

  Widget _buildDashboard(BuildContext context, DemandForecastResponse data) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text(
          '7-Day Workforce Allocation',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Generated: ${DateFormat('MMM d, h:mm a').format(data.generatedAt.toLocal())}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.md),
        ...data.forecasts.map((cf) => _buildCategoryCard(context, cf)),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryForecast cf) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cf.category,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                children: [
                  Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Demand', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Supply', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              ...cf.dailyForecasts.map((df) {
                final isShortage = df.status == 'shortage';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(_dateFormat.format(df.date.toLocal())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(df.predictedDemand.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(df.availableSupply.toStringAsFixed(0)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isShortage ? 'SHORTAGE' : 'SUFFICIENT',
                            style: TextStyle(
                              color: isShortage ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isShortage 
                                ? '${(df.predictedDemand - df.availableSupply).ceil()} additional workers recommended' 
                                : 'Workforce sufficient',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
