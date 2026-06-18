import 'package:flutter/foundation.dart';
import 'package:appambit_sdk_flutter/appambit_cms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organization_app_starter/core/constants.dart';
import 'package:organization_app_starter/features/home/models/feed_collection.dart';
import 'package:organization_app_starter/features/home/models/content_detail.dart';

/// Fetches all feed_collection records (parent sections), sorted by display_order.
///
/// Each [FeedCollection] contains its child [CollectionItem]s already parsed
/// in [collection]. Only [FeedCollection] has [displayOrder]; child items do not.
final homeFeedSectionsProvider = FutureProvider<List<FeedCollection>>((
  ref,
) async {
  try {
    debugPrint('[HomeFeed] Fetching live data from CMS (feed_carousel)...');

    // Query the live CMS data using AppAmbit SDK
    final sections = await AppAmbitCms.content<FeedCollection>(
      CmsContentType.feedCarousel,
      fromJson: (json) => FeedCollection.fromMap(json),
    ).getList();

    debugPrint('[HomeFeed] Raw live sections fetched: ${sections.length}');

    // Double sort guarantee
    final sorted = sections.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    debugPrint('[HomeFeed] Sorted sections: ${sorted.length}');
    for (final s in sorted) {
      debugPrint(
        '  [${s.displayOrder}] ${s.lookupKey} '
        '(${s.cardType.name}, collection: ${s.isCollection}, '
        'items: ${s.items.length})',
      );
    }

    return sorted;
  } catch (e, st) {
    debugPrint('[HomeFeed] ERROR loading live sections: $e\n$st');
    rethrow;
  }
});

/// Fetches a specific [ContentDetail] by its ID.
final contentDetailProvider = FutureProvider.family<ContentDetail?, String>((ref, id) async {
  try {
    debugPrint('[ContentDetail] Fetching details for ID: $id');
    final details = await AppAmbitCms.content<ContentDetail>(
      CmsContentType.contentDetails,
      fromJson: (json) => ContentDetail.fromMap(json),
    ).equals('id', id).getList();

    if (details.isEmpty) {
      debugPrint('[ContentDetail] No detail found for ID: $id');
      return null;
    }
    return details.first;
  } catch (e, st) {
    debugPrint('[ContentDetail] ERROR loading detail $id: $e\n$st');
    rethrow;
  }
});
