import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/app/app_providers.dart';
import 'package:organization_app_starter/app/app_shell.dart';
import 'package:organization_app_starter/core/config/app_config.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/core/styles/app_theme.dart';
import 'package:organization_app_starter/features/auth/models/user_model.dart';
import 'package:organization_app_starter/features/auth/providers/auth_providers.dart';
import 'package:organization_app_starter/features/auth/screens/auth_gate_screen.dart';
import 'package:organization_app_starter/shared/widgets/snackbar_app_widget.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  final prevOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
    prevOnError?.call(details);
  };

  await AppAmbitSdk.start(appKey: AppConfig.appKey);

  PushNotificationsSdk.start();
  PushNotificationsSdk.Android.setBackgroundHandler(
      backgroundNotificationHandler);

  runApp(const ProviderScope(child: _AppRoot()));
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  void _navigate(WidgetRef ref, AsyncValue<AuthUser?> next) {
    final isLoggedIn = next.asData?.value != null;
    if (next is AsyncLoading) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    if (isLoggedIn) {
      ref.read(selectedTabIndexProvider.notifier).select(0);
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const AppShell() : const AuthGateScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthSessionEvent?>(authSessionEventProvider, (_, event) {
      if (event == AuthSessionEvent.remotelyInvalidated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarAppWidget.show(
            'Your session was closed. You signed in on another device.',
            type: SnackBarType.warning,
          );
        });
        ref.read(authSessionEventProvider.notifier).clear();
      }
    });

    ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(ref, next));
    });

    final theme = AppTheme.light(AppTheme.textTheme(context));

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: theme,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
