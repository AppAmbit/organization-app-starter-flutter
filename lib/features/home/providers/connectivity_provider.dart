import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/shared/services/connectivity_service.dart';

/// Checks connectivity once at app launch (not a stream — only for initial check).
/// Returns true if the device has any network access.
final connectivityProvider = FutureProvider<bool>((ref) async {
  return ConnectivityService.isConnected();
});
