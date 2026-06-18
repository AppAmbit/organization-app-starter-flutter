import 'collection_item.dart';
import '_cms_map_utils.dart';

/// Card rendering style — defines how the cards in this section are displayed.
enum CardType { featured, large, small }

/// Represents a parent section in the Home Feed.
///
/// Maps to the `feed_collection` content type in the CMS.
/// Has a [displayOrder] field that defines its vertical position in the feed.
///
/// When [isCollection] is `true`, it holds child [CollectionItem]s in [collection].
/// When [isCollection] is `false`, the parent itself acts as a single card.
class FeedCollection {
  final String id;
  final String lookupKey;
  final String? title;
  final String? subtitle;
  final CardType cardType;
  final bool isCollection;
  final String? imageUrl;
  final String? image;
  final String? badge;
  final String? contentId;
  final int displayOrder;
  final List<CollectionItem> collection;

  const FeedCollection({
    required this.id,
    required this.lookupKey,
    this.title,
    this.subtitle,
    required this.cardType,
    required this.isCollection,
    this.imageUrl,
    this.image,
    this.badge,
    this.contentId,
    required this.displayOrder,
    this.collection = const [],
  });

  factory FeedCollection.fromMap(Map<String, dynamic> map) {
    final rawCollection = map['carousel'] ?? map['collection'];

    // Platform channel returns Map<Object?, Object?> — must cast explicitly
    final List<CollectionItem> children;
    if (rawCollection is List) {
      children = rawCollection
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(CollectionItem.fromMap)
          .toList();
    } else {
      children = [];
    }

    return FeedCollection(
      id: cmsFallbackId(map),
      lookupKey: map['lookup_key']?.toString() ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      cardType: _parseCardType(map['card_type'] as String?),
      isCollection: cmsParseBool(map['is_collection']),
      imageUrl: cmsResolveImageUrl(map),
      image: map['image'] as String?,
      badge: map['badge'] as String?,
      contentId: cmsResolveContentId(map),
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      collection: children,
    );
  }

  /// Returns the renderable items for this section.
  ///
  /// - `isCollection == true`  → returns the child [collection]
  /// - `isCollection == false` → wraps the parent as a single [CollectionItem]
  List<CollectionItem> get items {
    if (isCollection) return collection;
    return [
      CollectionItem(
        id: id,
        lookupKey: lookupKey,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        image: image,
        badge: badge,
        contentId: contentId,
      ),
    ];
  }

  static CardType _parseCardType(String? value) {
    switch (value) {
      case 'featured':
        return CardType.featured;
      case 'large':
        return CardType.large;
      case 'small':
        return CardType.small;
      default:
        return CardType.large;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeedCollection && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FeedCollection(id: $id, lookup: $lookupKey, type: $cardType, '
      'isCollection: $isCollection, children: ${collection.length}, '
      'order: $displayOrder)';
}
