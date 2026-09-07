import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';

class NotificationsScreen extends StatefulWidget {
  final Future<List<AppNotification>> Function() loadNotifications;
  final Future<AppNotification> Function(int id) markRead;

  NotificationsScreen({
    super.key,
    Future<List<AppNotification>> Function()? loadNotifications,
    Future<AppNotification> Function(int id)? markRead,
  }) : loadNotifications =
           loadNotifications ?? NotificationService().getNotifications,
       markRead = markRead ?? NotificationService().markRead;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.loadNotifications();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const AppLoading(message: 'Loading notifications')
        : _error != null
        ? AppErrorState(message: _error!, onRetry: _load)
        : _items.isEmpty
        ? const AppEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            subtitle: 'Updates about your activity will appear here.',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: _items.length,
            itemBuilder: (context, index) => _item(context, _items[index]),
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }

  Widget _item(BuildContext context, AppNotification item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: item.isRead
            ? null
            : () async {
                await widget.markRead(item.id);
                if (mounted) _load();
              },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: item.isRead ? null : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(item.message),
                  if (!item.isRead)
                    Text(
                      'Unread',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
