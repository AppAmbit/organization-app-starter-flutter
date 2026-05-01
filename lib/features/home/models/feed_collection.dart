import 'package:flutter/foundation.dart';
import 'collection_item.dart';

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
  final int displayOrder;         // Only feed_collection has this field
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

    // DEBUG: log what the SDK actually returns for collection
    debugPrint(
      '[FeedCollection] id=${map['id']} lookup=${map['lookup_key']} '
      'is_collection=${map['is_collection']} '
      'collection type=${rawCollection?.runtimeType} '
      'collection length=${rawCollection is List ? rawCollection.length : 'N/A'}',
    );
    if (rawCollection is List && rawCollection.isNotEmpty) {
      debugPrint(
        '[FeedCollection] first item type=${rawCollection.first?.runtimeType} '
        'first item=${rawCollection.first}',
      );
    }

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

    debugPrint(
      '[FeedCollection] parsed children: ${children.length} for ${map['lookup_key']}',
    );

    return FeedCollection(
      id: map['id']?.toString() ?? map['lookup_key']?.toString() ?? '',
      lookupKey: map['lookup_key']?.toString() ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      cardType: _parseCardType(map['card_type'] as String?),
      isCollection: _parseBool(map['is_collection']),
      imageUrl: _resolveImageUrl(map),
      image: map['image'] as String?,
      badge: map['badge'] as String?,
      contentId: _resolveContentId(map),
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

  static String? _resolveContentId(Map<String, dynamic> map) {
    final content = map['content'];
    final contentDetail = map['content_detail'];
    
    debugPrint('[FeedCollection] resolving contentId for lookup=${map['lookup_key']}. content=${content?.runtimeType}, content_detail=${contentDetail?.runtimeType}');
    
    if (content is Map) {
      return content['id']?.toString();
    } else if (content is String) {
      return content;
    }
    
    if (contentDetail is Map) {
      return contentDetail['id']?.toString();
    } else if (contentDetail is String) {
      return contentDetail;
    }
    return null;
  }

  static String? _resolveImageUrl(Map<String, dynamic> map) {
    final resolvedUrl = map['image_url'];
    if (resolvedUrl is String && resolvedUrl.isNotEmpty) return resolvedUrl;
    final raw = map['image'];
    if (raw is String && raw.isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
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
