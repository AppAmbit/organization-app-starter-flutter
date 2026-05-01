import 'package:flutter/material.dart';
import '../../core/styles/app_colors.dart';
import '../../main.dart'; // Para rootNavigatorKey
import '../../shared/domain/enums/data_general.dart';
export '../../shared/domain/enums/data_general.dart';

class SnackBarAppWidget {
  static show(
    String message, {
    SnackBarType type = SnackBarType.normal,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return; // Silent no-op when no UI available (tests/background)
    final icon = _getIcon(type);
    final bgColor = _getColor(type);

    // If we can access an Overlay, insert a floating OverlayEntry so the
    // snackbar appears above modal sheets. Try navigator's overlay first,
    // fallback to Overlay.of(context), then ScaffoldMessenger.
    final overlayState = rootNavigatorKey.currentState?.overlay ?? Overlay.of(context);
    const duration = Duration(seconds: 3);
    if (overlayState != null) {
      // Remove any existing overlay snackbar first
      hideCurrent();

      final entry = OverlayEntry(
        builder: (overlayContext) {
          final width = MediaQuery.of(overlayContext).size.width;
          return Positioned(
            bottom: 20,
            left: width * 0.05,
            right: width * 0.05,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message, 
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )
                      )
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

    // Fallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: AppColors.white))),
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

  static OverlayEntry? _currentOverlayEntry;

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
