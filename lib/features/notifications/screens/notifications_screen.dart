import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/styles/app_colors.dart';
import '../../home/models/collection_item.dart';
import '../../home/screens/content_detail_screen.dart';
import '../models/notification_model.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final asyncItems = ref.watch(notificationsProvider);
    final notificationsNotifier = ref.read(notificationsProvider.notifier);
    final pushEnabled = ref.watch(pushEnabledProvider).value ?? true;

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 32, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 24,
                        color: AppColors.textPrimary,
                      ),
                      onSelected: (value) async {
                        if (value == 'mark_all_read') {
                          await notificationsNotifier.markAllRead();
                        } else if (value == 'clear_all') {
                          await notificationsNotifier.clear();
                        } else if (value == 'toggle_notifications') {
                          await ref
                              .read(pushEnabledProvider.notifier)
                              .toggle(!pushEnabled);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'mark_all_read',
                          child: Text('Mark all as read'),
                        ),
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Text('Clear all'),
                        ),
                        PopupMenuItem(
                          value: 'toggle_notifications',
                          child: Text(
                            pushEnabled
                                ? 'Disable notifications'
                                : 'Enable notifications',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stay updated with the latest activity',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const _EmptyState(
                message: 'Could not load notifications.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyState(message: 'No notifications yet.');
                }
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: _dismissBackground(),
                        onDismissed: (_) =>
                            notificationsNotifier.delete(item.id),
                        child: NotificationTile(
                          notification: item,
                          onTap: () => _onTap(context, ref, item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, NotificationModel item) {
    ref.read(notificationsProvider.notifier).markRead(item.id);
    if (item.route == 'content_detail' &&
        (item.contentId?.isNotEmpty ?? false)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen(
            item: CollectionItem(
              id: item.contentId!,
              lookupKey: '',
              title: item.title.isEmpty ? null : item.title,
              contentId: item.contentId,
            ),
          ),
        ),
      );
    }
  }

  Widget _dismissBackground() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.badgeRed,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none,
              size: 64, color: AppColors.gray400),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
