import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app_shell.dart';
import 'core/config/app_config.dart';
import 'core/constants.dart';
import 'core/styles/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
  };

  await AppAmbitSdk.start(appKey: AppConfig.appKey);

  PushNotificationsSdk.start();
  PushNotificationsSdk.Android.setBackgroundHandler(
      backgroundNotificationHandler);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.textTheme(context);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: AppTheme.light(textTheme),
      home: const AppShell(),
    );
  }
}
