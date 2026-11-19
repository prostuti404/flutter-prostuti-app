import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prostuti/common/widgets/common_widgets/common_widgets.dart';
import 'package:prostuti/core/services/localization_service.dart';

import '../model/notification_model.dart';
import '../viewmodel/notification_viewmodel.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with CommonWidgets {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppbar(context.l10n!.notification),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationViewModelProvider.notifier)
              .refreshNotifications();
        },
        child: Consumer(
          builder: (context, ref, child) {
            final notificationsAsync = ref.watch(notificationViewModelProvider);

            return notificationsAsync.when(
              data: (notifications) {
                final notificationViewModel =
                    ref.read(notificationViewModelProvider.notifier);
                final todayNotifications =
                    notificationViewModel.todayNotifications;
                final previousNotifications =
                    notificationViewModel.previousNotifications;

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications available'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Notifications
                      if (todayNotifications.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            context.l10n!.todaysNotices,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...todayNotifications.map(
                          (notification) =>
                              NotificationCard(notification: notification),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Previous Notifications
                      if (previousNotifications.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            context.l10n!.olderNotices,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...previousNotifications.map(
                          (notification) =>
                              NotificationCard(notification: notification),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error loading notifications: $error'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends ConsumerWidget {
  final Data notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  String _getTimeAgo(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return '2 mins ago'; // Default fallback for the design
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = notification.isRead == false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isUnread && notification.sId != null
            ? () => ref
                .read(notificationViewModelProvider.notifier)
                .markAsRead(notification.sId!)
            : null,
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title ?? 'Exam Reminder',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUnread)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: CircleAvatar(radius: 4, backgroundColor: Colors.blue),
                  ),
                Text(
                  _getTimeAgo(notification.createdAt ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.message ??
                  "I've finished adding my notes. Happy for us to review whenever you're ready!",
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
