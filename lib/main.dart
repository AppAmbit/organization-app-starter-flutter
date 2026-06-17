import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/models/collection_item.dart';
import 'features/home/screens/content_detail_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/notifications/models/notification_model.dart';
import 'features/notifications/providers/notifications_providers.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'shared/widgets/snackbar_app_widget.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Runs in an isolated headless engine when Android delivers a notification
/// while the app is backgrounded or terminated. No UI, no providers available.
/// Writes directly to SharedPreferences so the main isolate picks it up on resume.
@pragma('vm:entry-point')
Future<void> _backgroundNotificationHandler(PushNotificationData payload) async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = NotificationModel.fromPush(payload);
  await NotificationsRepository().upsert(model);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
  };

  // Core SDK order (README): enable config first, then start core.
  //AppAmbitSdk.enableConfig();

  final appKey = Platform.isIOS
      ? dotenv.env['APPAMBIT_APPKEY_IOS'] ?? ''
      : dotenv.env['APPAMBIT_APPKEY_ANDROID'] ?? '';
  await AppAmbitSdk.start(appKey: appKey);

  // Push SDK order (README): start, register background handler, then request OS permission.
  PushNotificationsSdk.start();
  PushNotificationsSdk.Android.setBackgroundHandler(_backgroundNotificationHandler);

  runApp(const ProviderScope(child: MainApp()));
}



class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'KavaUp CMS App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent, surface: AppColors.white),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.white,
          titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.black, letterSpacing: -0.5),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.gray500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class BottomBarVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void show() => state = true;
  void hide() => state = false;
}

final bottomBarVisibleProvider = NotifierProvider<BottomBarVisibleNotifier, bool>(BottomBarVisibleNotifier.new);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const int _notificationsTabIndex = 3;
  int _selectedIndex = 0;

  static const _pages = <Widget>[HomeScreen(), Center(child: Text('Categories')), Center(child: Text('Resources')), NotificationsScreen(), Center(child: Text('About'))];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Ask for notification permission at startup (same pattern as example app).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission = await PushNotificationsSdk.hasNotificationPermission();

      if (hasPermission) {
        // OS permission already granted. Give APNs ~2s to deliver the device
        // token before syncing — otherwise getCurrentToken() returns empty and
        // ConsumerService never reaches the backend (handles token rotation too).
        await Future.delayed(const Duration(seconds: 2));
        await PushNotificationsSdk.setNotificationsEnabled(true);
        return;
      }

      // No OS permission yet — show the system dialog.
      bool isGranted = false;
      await PushNotificationsSdk.requestNotificationPermission(
        callback: (granted) => isGranted = granted,
      );
      if (isGranted) {
        await Future.delayed(const Duration(seconds: 2));
        await PushNotificationsSdk.setNotificationsEnabled(true);
      } else {
        SnackBarAppWidget.show(
          'Para recibir alertas importantes, habilita notificaciones.',
          type: SnackBarType.warning,
        );
      }
    });

    // Foreground push: app is open → write straight to the provider for an
    // instant UI update (also persists).
    PushNotificationsSdk.setForegroundListener((data) {
      ref.read(notificationsProvider.notifier).add(NotificationModel.fromPush(data));
    });

    // Tapped push: the record already exists (written by a foreground/
    // background/NSE writer). Mark it read and route by the data keys.
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
      // Reconcile out-of-band writers: Android background isolate (re-read
      // prefs) and iOS NSE (drain App Group queue).
      ref.read(notificationsProvider.notifier).reload();
    }
  }

  void _handleOpened(PushNotificationData data) {
    final model = NotificationModel.fromPush(data);
    AppAmbitSdk.trackEvent('Notification Opened', {
      'title': model.title,
      'body': model.message,
    });
    ref.read(notificationsProvider.notifier).markRead(model.id);

    if (model.route == 'content_detail' && (model.contentId?.isNotEmpty ?? false)) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen(
            item: CollectionItem(
              id: model.contentId!,
              lookupKey: '',
              title: model.title.isEmpty ? null : model.title,
              contentId: model.contentId,
            ),
          ),
        ),
      );
    } else if (mounted) {
      setState(() => _selectedIndex = _notificationsTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(bottomBarVisibleProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isTablet = size.shortestSide >= 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final contentMaxWidth = isTablet
        ? (isLandscape ? 1100.0 : 820.0)
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
        child: isVisible
            ? Align(
                alignment: Alignment.topCenter,
                heightFactor: 1.0, // Prevents expanding vertically
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: shellPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: _AnimatedBottomTabBar(
                      currentIndex: _selectedIndex,
                      unreadCount: unreadCount,
                      isTablet: isTablet,
                      onTap: (index) => setState(() => _selectedIndex = index),
                    ),
                  ),
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }
}

class _AnimatedBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final bool isTablet;
  final ValueChanged<int> onTap;

  const _AnimatedBottomTabBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _TabItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _TabItemData(icon: Icons.grid_view, activeIcon: Icons.grid_view_rounded, label: 'Categories'),
      _TabItemData(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Resources'),
      _TabItemData(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications', badgeCount: unreadCount),
      _TabItemData(icon: Icons.info_outline, activeIcon: Icons.info, label: 'About'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.gray500.withValues(alpha: 0.2), width: 1)),
        boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: isTablet ? 10 : 8, bottom: isTablet ? 8 : 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _AnimatedTabItem(
                data: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
                accentColor: AppColors.accent,
                isTablet: isTablet,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  _TabItemData({required this.icon, required this.activeIcon, required this.label, this.badgeCount = 0});
}

class _AnimatedTabItem extends StatelessWidget {
  final _TabItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isTablet;

  const _AnimatedTabItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = AppColors.gray500;
    final iconBoxWidth = isTablet ? 46.0 : 40.0;
    final iconBoxHeight = isTablet ? 38.0 : 34.0;
    final iconSize = isTablet ? 24.0 : 22.0;
    final labelFontSize = isTablet ? 11.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(isSelected ? 1.05 : 1.0, isSelected ? 1.05 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon wrapper with active background and Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: iconBoxWidth,
                  height: iconBoxHeight,
                  decoration: BoxDecoration(color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isSelected ? data.activeIcon : data.icon, color: isSelected ? accentColor : inactiveColor, size: iconSize),
                ),
                if (data.badgeCount > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.badgeRed, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          data.badgeCount > 9 ? '9+' : data.badgeCount.toString(),
                          style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Indicator Dot (animates width 0 to 24)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(1.5)),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              data.label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
