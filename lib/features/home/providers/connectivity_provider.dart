import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Checks connectivity once at app launch (not a stream — only for initial check).
/// Returns true if the device has any network access.
final connectivityProvider = FutureProvider<bool>((ref) async {
  final result = await Connectivity().checkConnectivity();
  return result.any((r) => r != ConnectivityResult.none);
});
