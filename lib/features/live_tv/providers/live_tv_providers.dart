import 'package:flutter/foundation.dart' show debugPrint;
import 'package:appambit_sdk_flutter/appambit_cms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/features/live_tv/models/live_channel.dart';

/// All live channels, sorted by display_order.
final liveChannelsProvider = FutureProvider<List<LiveChannel>>((ref) async {
  try {
    final list = await AppAmbitCms.content<LiveChannel>(
      CmsContentType.liveChannels,
      fromJson: (json) => LiveChannel.fromMap(json),
    ).getList();
    return list;
  } catch (e, st) {
    debugPrint('[LiveTV] ERROR loading live channels: $e\n$st');
    rethrow;
  }
});
