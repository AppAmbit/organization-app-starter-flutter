import 'package:flutter/material.dart';

/// Whitelist of icon keys the backend may send in the push payload under the
/// `icon` data key, mapped to const Material icons.
///
/// Values are const `Icons.*`, so this stays tree-shake safe (no
/// `--no-tree-shake-icons` needed). The string is sent by the backend; the icon
/// shown in the list is resolved here, decoupled from the system tray icon.
const Map<String, IconData> kNotificationIcons = {
  'article': Icons.article_outlined,
  'folder': Icons.folder_outlined,
  'star': Icons.star_border_rounded,
  'notifications': Icons.notifications_outlined,
  'verified_user': Icons.verified_user_outlined,
  'campaign': Icons.campaign_outlined,
  'info': Icons.info_outline,
  'settings': Icons.settings_outlined,
  'download': Icons.download_outlined,
  'calendar': Icons.calendar_today_outlined,
  'person': Icons.person_outline,
  'warning': Icons.warning_amber_outlined,
};

/// Default icon used when the key is missing or not in [kNotificationIcons].
const IconData kNotificationFallbackIcon = Icons.notifications_outlined;

/// Resolves a backend icon key to a Material icon, falling back to a default.
IconData iconFor(String? key) =>
    kNotificationIcons[key] ?? kNotificationFallbackIcon;
