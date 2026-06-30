import 'package:flutter/material.dart';
import 'package:organization_app_starter/core/styles/app_colors.dart';

typedef _Tab = ({IconData icon, IconData activeIcon, String label});

const List<_Tab> _kTabs = [
  (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  (icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'Live TV'),
  (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Categories'),
  (icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
  (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
];

class AnimatedBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final bool isTablet;
  final ValueChanged<int> onTap;

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
              color: AppColors.white.withValues(alpha: 0.05),
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
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;

  const _AnimatedTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.accent;
    final inactiveColor = AppColors.gray500;
    final iconSize = isTablet ? 24.0 : 22.0;
    final labelFontSize = isTablet ? 11.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: isTablet ? 72 : 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? accentColor : inactiveColor,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : inactiveColor,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
