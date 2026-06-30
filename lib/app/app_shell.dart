import 'package:flutter/material.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/features/home/models/collection_item.dart';
import 'package:organization_app_starter/features/home/screens/home_screen.dart';
import 'package:organization_app_starter/features/live_tv/screens/live_tv_screen.dart';
import 'package:organization_app_starter/features/categories/screens/categories_screen.dart';
import 'package:organization_app_starter/features/search/screens/search_screen.dart';
import 'package:organization_app_starter/features/settings/screens/settings_screen.dart';
import 'package:organization_app_starter/features/notifications/data/notifications_repository.dart';
import 'package:organization_app_starter/features/notifications/models/notification_model.dart';
import 'package:organization_app_starter/features/notifications/providers/notifications_providers.dart';
import 'package:organization_app_starter/features/notifications/screens/notifications_screen.dart';
import 'package:organization_app_starter/shared/services/analytics_service.dart';
import 'package:organization_app_starter/shared/services/navigation_service.dart';
import 'package:organization_app_starter/shared/widgets/snackbar_app_widget.dart';
import 'app_providers.dart';
import 'bottom_tab_bar.dart';

// Defined in main.dart — needed here for the opened-push navigator.
import 'package:organization_app_starter/main.dart' show rootNavigatorKey;

/// Runs in an isolated headless engine when Android delivers a notification
/// while the app is backgrounded or terminated. Writes directly to
/// SharedPreferences so the main isolate picks it up on resume.
@pragma('vm:entry-point')
Future<void> backgroundNotificationHandler(PushNotificationData payload) async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = NotificationModel.fromPush(payload);
  await NotificationsRepository().upsert(model);
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    LiveTvScreen(),
    CategoriesScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission =
          await PushNotificationsSdk.hasNotificationPermission();

      if (hasPermission) {
        await Future.delayed(const Duration(seconds: 2));
        await PushNotificationsSdk.setNotificationsEnabled(true);
        return;
      }

      bool isGranted = false;
      await PushNotificationsSdk.requestNotificationPermission(
        callback: (granted) => isGranted = granted,
      );
      if (isGranted) {
        await Future.delayed(const Duration(seconds: 2));
        await PushNotificationsSdk.setNotificationsEnabled(true);
      } else {
        SnackBarAppWidget.show(
          'Enable notifications to receive important alerts.',
          type: SnackBarType.warning,
        );
      }
    });

    PushNotificationsSdk.setForegroundListener((data) {
      ref
          .read(notificationsProvider.notifier)
          .add(NotificationModel.fromPush(data));
    });

    PushNotificationsSdk.setOpenedListener(_handleOpened);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationsProvider.notifier).reload();
    }
  }

  void _handleOpened(PushNotificationData data) {
    final model = NotificationModel.fromPush(data);
    AnalyticsService.trackNotificationOpened(
        title: model.title, body: model.message);
    ref.read(notificationsProvider.notifier).markRead(model.id);

    if (model.route == NotificationRoute.contentDetail &&
        (model.contentId?.isNotEmpty ?? false)) {
      rootNavigatorKey.currentState?.push(
        NavigationService.contentDetailRoute(
          CollectionItem(
            id: model.contentId!,
            lookupKey: '',
            title: model.title.isEmpty ? null : model.title,
            contentId: model.contentId,
          ),
        ),
      );
    } else if (mounted) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(bottomBarVisibleProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isTablet = size.shortestSide >= AppLayout.tabletBreakpoint;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final contentMaxWidth = isTablet
        ? (isLandscape
            ? AppLayout.maxWidthTabletLandscape
            : AppLayout.maxWidthTabletPortrait)
        : double.infinity;
    final shellPadding = isTablet ? (isLandscape ? 24.0 : 16.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: shellPadding),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _pages[_selectedIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: isVisible ? null : 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: shellPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: AnimatedBottomTabBar(
                currentIndex: _selectedIndex,
                unreadCount: unreadCount,
                isTablet: isTablet,
                onTap: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
