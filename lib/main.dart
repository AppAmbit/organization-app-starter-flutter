import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/screens/home_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
  };

  await AppAmbitSdk.start(appKey: '94c60591-c195-4b69-b72f-a4b6f4dda908');

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4338CA),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4338CA),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
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

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    Center(child: Text('Categories')),
    Center(child: Text('Resources')),
    NotificationsScreen(),
    Center(child: Text('About')),
  ];

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(bottomBarVisibleProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the letterbox area
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _pages[_selectedIndex],
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _AnimatedBottomTabBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
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
  final ValueChanged<int> onTap;

  const _AnimatedBottomTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _TabItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _TabItemData(icon: Icons.grid_view, activeIcon: Icons.grid_view_rounded, label: 'Categories'),
      _TabItemData(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Resources'),
      _TabItemData(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts', badgeCount: 3),
      _TabItemData(icon: Icons.info_outline, activeIcon: Icons.info, label: 'About'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _AnimatedTabItem(
                data: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
                accentColor: theme.colorScheme.primary,
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
  
  _TabItemData({
    required this.icon, 
    required this.activeIcon, 
    required this.label,
    this.badgeCount = 0,
  });
}

class _AnimatedTabItem extends StatelessWidget {
  final _TabItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _AnimatedTabItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.grey[500]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          isSelected ? 1.05 : 1.0, 
          isSelected ? 1.05 : 1.0, 
          1.0,
        ),
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
                  width: 44,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? data.activeIcon : data.icon,
                    color: isSelected ? accentColor : inactiveColor,
                    size: 22,
                  ),
                ),
                if (data.badgeCount > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          data.badgeCount > 9 ? '9+' : data.badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
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
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              data.label,
              style: TextStyle(
                fontSize: 10,
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
