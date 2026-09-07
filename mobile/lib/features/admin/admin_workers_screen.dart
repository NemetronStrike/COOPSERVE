import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class AdminWorkersScreen extends StatefulWidget {
  final Future<List<AdminWorker>> Function(String status) loadWorkers;
  final Future<AdminWorker> Function(int id, String status) updateVerification;

  AdminWorkersScreen({
    super.key,
    Future<List<AdminWorker>> Function(String status)? loadWorkers,
    Future<AdminWorker> Function(int id, String status)? updateVerification,
  }) : loadWorkers =
           loadWorkers ??
           ((status) => AdminService().getWorkers(status: status)),
       updateVerification =
           updateVerification ??
           ((id, status) => AdminService().updateVerification(id, status));

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  List<AdminWorker> _workers = const [];
  String _filter = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final workers = await widget.loadWorkers(_filter);
      if (!mounted) return;
      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Verification')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Row(
              children: ['all', 'pending', 'verified', 'rejected']
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: _filter == status,
                        onSelected: (_) {
                          setState(() => _filter = status);
                          _load();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const AppLoading(message: 'Loading workers')
                : _error != null
                ? AppErrorState(message: _error!, onRetry: _load)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: _workers.length,
                    itemBuilder: (context, index) =>
                        _workerCard(context, _workers[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _workerCard(BuildContext context, AdminWorker worker) {
    final nextStatus = worker.verificationStatus == 'verified'
        ? 'rejected'
        : 'verified';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker.name, style: Theme.of(context).textTheme.titleMedium),
            Text(worker.skills.join(' • ')),
            Text(
              '${worker.experienceYears ?? 0} years • ${worker.rating.toStringAsFixed(1)} rating • ${worker.totalJobs} jobs',
            ),
            Text('Status: ${worker.verificationStatus}'),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: () => _update(worker, nextStatus),
              child: Text(
                nextStatus == 'verified' ? 'Verify Worker' : 'Reject Worker',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(AdminWorker worker, String status) async {
    await widget.updateVerification(worker.id, status);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Worker ${status == 'verified' ? 'verified' : 'rejected'} successfully.',
        ),
      ),
    );
    _load();
  }
}
