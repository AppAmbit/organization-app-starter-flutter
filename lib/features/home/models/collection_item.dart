import '_cms_map_utils.dart';

/// Represents a single card item inside a [FeedCollection] section.
///
/// Maps to the child records inside the `collection` relation field.
/// Does NOT have a `display_order` field — order is defined by the parent's
/// relation list order in the CMS.
class CollectionItem {
  final String id;
  final String lookupKey;
  final String? title;
  final String? subtitle;
  final String? imageUrl;   // Resolved from image_url (full URL) — prioritized
  final String? image;      // Raw filename from the media field
  final String? badge;
  final String? body;       // Optional HTML body content
  final String? contentId;
  final String? floatingImageUrl; // Optional logo/image floated above the title (featured cards)
  final String? overlayText;      // Optional transient overlay label shown over the image (featured cards)

  const CollectionItem({
    required this.id,
    required this.lookupKey,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.image,
    this.badge,
    this.body,
    this.contentId,
    this.floatingImageUrl,
    this.overlayText,
  });

  /// Parses a child item from the CMS JSON.
  ///
  /// Media convention: the backend generates `image_url` (full URL) alongside
  /// `image` (raw filename). We always prioritize `image_url`.
  factory CollectionItem.fromMap(Map<String, dynamic> map) {
    final resolvedContentId = cmsResolveContentId(map);
    return CollectionItem(
      id: cmsFallbackId(map),
      lookupKey: map['lookup_key']?.toString() ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      imageUrl: cmsResolveImageUrl(map),
      image: map['image'] as String?,
      badge: map['badge'] as String?,
      body: map['body'] as String?,
      contentId: resolvedContentId,
      floatingImageUrl: cmsResolveFloatingImageUrl(map),
      overlayText: map['overlay_text'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CollectionItem && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CollectionItem(id: $id, lookup: $lookupKey, badge: $badge)';
}
