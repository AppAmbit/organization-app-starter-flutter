import 'package:flutter/material.dart';

import 'package:organization_app_starter/core/styles/app_colors.dart';
import 'package:organization_app_starter/main.dart';
import 'package:organization_app_starter/shared/domain/enums/data_general.dart';

export '../domain/enums/data_general.dart';

class SnackBarAppWidget {
  static OverlayEntry? _currentOverlayEntry;

  static void show(
    String message, {
    SnackBarType type = SnackBarType.normal,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final icon = _getIcon(type);
    final bgColor = _getColor(type);
    final overlayState =
        rootNavigatorKey.currentState?.overlay ?? Overlay.maybeOf(context);

    const duration = Duration(seconds: 3);
    if (overlayState != null) {
      hideCurrent();

      final entry = OverlayEntry(
        builder: (overlayContext) {
          final width = MediaQuery.of(overlayContext).size.width;
          return Positioned(
            bottom: 20,
            left: width * 0.1,
            right: width * 0.1,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      _currentOverlayEntry = entry;
      overlayState.insert(entry);
      Future.delayed(duration, () {
        try {
          entry.remove();
        } catch (_) {}
        if (_currentOverlayEntry == entry) _currentOverlayEntry = null;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: bgColor,
        duration: duration,
      ),
    );
  }

  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
      case SnackBarType.normal:
        return Icons.notifications_rounded;
    }
  }

  static Color _getColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.accentRed;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.info;
      case SnackBarType.normal:
        return AppColors.gray900;
    }
  }

  static void hideCurrent() {
    if (_currentOverlayEntry != null) {
      try {
        _currentOverlayEntry?.remove();
      } catch (_) {}
      _currentOverlayEntry = null;
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
