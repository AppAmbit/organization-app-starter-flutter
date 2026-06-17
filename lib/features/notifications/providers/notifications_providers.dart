import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';

import '../../../shared/widgets/snackbar_app_widget.dart';
import '../data/ios_notification_bridge.dart';
import '../data/notifications_repository.dart';
import '../models/notification_model.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository());

/// Canonical, persisted notification list for the UI.
///
/// Coexistence model (see also the iOS NSE and Android background handler):
/// - Foreground pushes call [add] directly (instant UI + persistence).
/// - Android background pushes are written to SharedPreferences by the
///   background isolate; [reload] re-reads them on app resume.
/// - iOS background pushes are written by the NSE into the App Group queue;
///   [build]/[reload] drain that queue and merge it in.
///
/// All paths upsert by id in the repository, so overlapping delivery is
/// idempotent.
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<List<NotificationModel>> build() => _loadAndDrain();

  Future<List<NotificationModel>> _loadAndDrain() async {
    final drained = await IosNotificationBridge.drainPending();
    if (drained.isNotEmpty) return _repo.upsertAll(drained);
    return _repo.load();
  }

  Future<void> add(NotificationModel item) async {
    state = AsyncData(await _repo.upsert(item));
  }

  Future<void> markRead(String id) async {
    state = AsyncData(await _repo.markRead(id));
  }

  Future<void> markAllRead() async {
    state = AsyncData(await _repo.markAllRead());
  }

  Future<void> delete(String id) async {
    state = AsyncData(await _repo.delete(id));
  }

  Future<void> clear() async {
    state = AsyncData(await _repo.clear());
  }

  /// Re-reads persisted state and drains any iOS NSE entries. Call on resume.
  Future<void> reload() async {
    state = AsyncData(await _loadAndDrain());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        NotificationsNotifier.new);

/// Live unread count — drives the bottom tab badge.
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (items) => items.where((e) => !e.read).length,
    orElse: () => 0,
  );
});

// ---------------------------------------------------------------------------
// Push enabled state
// ---------------------------------------------------------------------------

class PushEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => PushNotificationsSdk.isNotificationsEnabled();

  Future<void> toggle(bool enabled) async {
    if (!enabled) {
      await PushNotificationsSdk.setNotificationsEnabled(false);
      final applied = await PushNotificationsSdk.isNotificationsEnabled();
      state = AsyncData(applied);
      if (!applied) {
        SnackBarAppWidget.show(
          'Notificaciones deshabilitadas.',
          type: SnackBarType.info,
        );
      } else {
        SnackBarAppWidget.show(
          'No se pudo deshabilitar notificaciones. Intenta de nuevo.',
          type: SnackBarType.error,
        );
      }
      return;
    }

    final hasPermission = await PushNotificationsSdk.hasNotificationPermission();
    if (!hasPermission) {
      bool isGranted = false;
      await PushNotificationsSdk.requestNotificationPermission(
        callback: (granted) => isGranted = granted,
      );
      if (!isGranted) {
        state = AsyncData(false);
        SnackBarAppWidget.show(
          'Para habilitarlas, acepta permisos de notificaciones.',
          type: SnackBarType.warning,
        );
        return;
      }
    }

    await PushNotificationsSdk.setNotificationsEnabled(true);
    final applied = await PushNotificationsSdk.isNotificationsEnabled();
    state = AsyncData(applied);
    if (applied) {
      SnackBarAppWidget.show(
        'Notificaciones habilitadas correctamente.',
        type: SnackBarType.success,
      );
    } else {
      SnackBarAppWidget.show(
        'No se pudo habilitar notificaciones. Intenta de nuevo.',
        type: SnackBarType.error,
      );
    }
  }
}

final pushEnabledProvider =
    AsyncNotifierProvider<PushEnabledNotifier, bool>(PushEnabledNotifier.new);
