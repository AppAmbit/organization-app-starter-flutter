import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';

typedef _Tab = ({IconData icon, IconData activeIcon, String label});

const List<_Tab> _kTabs = [
  (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  (icon: Icons.grid_view, activeIcon: Icons.grid_view_rounded, label: 'Categories'),
  (icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Resources'),
  (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications'),
  (icon: Icons.info_outline, activeIcon: Icons.info, label: 'About'),
  (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
];

class AnimatedBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final bool isTablet;
  final ValueChanged<int> onTap;

  static const int _notificationsIndex = 3;

  const AnimatedBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.unreadCount,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: AppColors.gray500.withValues(alpha: 0.2), width: 1)),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              top: isTablet ? 10 : 8, bottom: isTablet ? 8 : 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_kTabs.length, (i) {
              final tab = _kTabs[i];
              return _AnimatedTabItem(
                icon: tab.icon,
                activeIcon: tab.activeIcon,
                label: tab.label,
                badgeCount: i == _notificationsIndex ? unreadCount : 0,
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
                isTablet: isTablet,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;

  const _AnimatedTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.badgeCount,
    required this.isSelected,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.accent;
    final inactiveColor = AppColors.gray500;
    final iconBoxWidth = isTablet ? 46.0 : 40.0;
    final iconBoxHeight = isTablet ? 38.0 : 34.0;
    final iconSize = isTablet ? 24.0 : 22.0;
    final labelFontSize = isTablet ? 11.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: iconBoxWidth,
                  height: iconBoxHeight,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? accentColor : inactiveColor,
                    size: iconSize,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.badgeRed, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(1.5)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
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
