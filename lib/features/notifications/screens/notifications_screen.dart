import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'package:organization_app_starter/shared/services/navigation_service.dart';
import 'package:organization_app_starter/features/notifications/models/notification_model.dart';
import 'package:organization_app_starter/features/notifications/providers/notifications_providers.dart';
import 'package:organization_app_starter/features/notifications/widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  bool _settingsVisible = false;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final asyncItems = ref.watch(notificationsProvider);
    final pushEnabled = ref.watch(pushEnabledProvider).value ?? true;
    final unreadCount = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        Container(
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
                        Row(
                          children: [
                            if (unreadCount > 0)
                              GestureDetector(
                                onTap: () =>
                                    ref.read(notificationsProvider.notifier).markAllRead(),
                                child: const Icon(
                                  Icons.done_all,
                                  size: 24,
                                  color: AppColors.accent,
                                ),
                              ),
                            if (unreadCount > 0) const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _settingsVisible = true),
                              child: const Icon(
                                Icons.settings,
                                size: 24,
                                color: AppColors.textSecondary,
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const _EmptyState(
                    message: 'Could not load notifications.',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyState(
                          message: 'No notifications yet.');
                    }
                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return NotificationTile(
                            notification: item,
                            onTap: () => _onTap(context, ref, item),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Settings modal overlay
        if (_settingsVisible) _SettingsModal(
          pushEnabled: pushEnabled,
          onToggle: (enabled) async {
            await ref.read(pushEnabledProvider.notifier).toggle(enabled);
          },
          onClose: () => setState(() => _settingsVisible = false),
        ),
      ],
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, NotificationModel item) {
    ref.read(notificationsProvider.notifier).markRead(item.id);
    if (item.route == NotificationRoute.contentDetail &&
        (item.contentId?.isNotEmpty ?? false)) {
      NavigationService.openContentDetail(
        context,
        CollectionItem(
          id: item.contentId!,
          lookupKey: '',
          title: item.title.isEmpty ? null : item.title,
          contentId: item.contentId,
        ),
      );
    }
  }
}

class _SettingsModal extends StatelessWidget {
  final bool pushEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onClose;

  const _SettingsModal({
    required this.pushEnabled,
    required this.onToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black38),
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(
                            Icons.close,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Push Notifications',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Receive alerts for new activity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: pushEnabled,
                          onChanged: onToggle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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
