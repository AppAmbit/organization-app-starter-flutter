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
///
/// Resolves content blocks via 2-step CMS fetch:
/// 1. Fetch `content_details` record (contains entry_id references in `.content`)
/// 2. Fetch `content_detail_items` records matching unresolved entry_ids
final contentDetailProvider = FutureProvider.family<ContentDetail?, String>((ref, id) async {
  try {
    debugPrint('[ContentDetail] Fetching details for ID: $id');

    // SDK filter-by-id not supported for content_details; fetch all and match in Dart.
    // Same approach as React Native reference implementation.
    final allDetails = await AppAmbitCms.content<Map<String, dynamic>>(
      CmsContentType.contentDetails,
      fromJson: (json) => Map<String, dynamic>.from(json),
    ).getList();

    final rawDetail = allDetails.where((e) => e['id']?.toString() == id).firstOrNull;
    if (rawDetail == null) {
      debugPrint('[ContentDetail] No content_details record for ID: $id');
      return null;
    }

    final partial = ContentDetail.fromMap(rawDetail);
    final blocks = List<ContentDetailBlock>.of(partial.contentBlocks);

    if (partial.unresolvedContentIds.isNotEmpty) {
      // entry_id stubs in content array — resolve against content_detail_items
      final allItems = await AppAmbitCms.content<Map<String, dynamic>>(
        CmsContentType.contentDetailItems,
        fromJson: (json) => Map<String, dynamic>.from(json),
      ).getList();

      final wantedIds = partial.unresolvedContentIds.toSet();
      final byId = <String, Map<String, dynamic>>{};
      for (final item in allItems) {
        final itemId = item['id']?.toString() ?? '';
        if (wantedIds.contains(itemId)) byId[itemId] = item;
      }
      for (final entryId in partial.unresolvedContentIds) {
        final found = byId[entryId];
        if (found != null) blocks.add(ContentDetailBlock.fromMap(found));
      }
      debugPrint('[ContentDetail] resolved ${blocks.length} blocks for id=$id');
    }

    return ContentDetail(
      id: partial.id,
      title: partial.title,
      contentBlocks: blocks,
    );
  } catch (e, st) {
    debugPrint('[ContentDetail] ERROR loading detail $id: $e\n$st');
    rethrow;
  }
});
