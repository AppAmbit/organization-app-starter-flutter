import 'package:organization_app_starter/shared/domain/cms_parse.dart';

/// A series / collection (maps to the `shows` CMS type).
/// Tied to a [category] slug — the relation between Home, Categories and Live TV.
class Show {
  final String id;
  final String title;
  final String? hawaiianName;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? category;
  final String? watchUrl;
  final int? episodeCount;
  final int displayOrder;

  const Show({
    required this.id,
    required this.title,
    this.hawaiianName,
    required this.slug,
    this.description,
    this.imageUrl,
    this.category,
    this.watchUrl,
    this.episodeCount,
    required this.displayOrder,
  });

  factory Show.fromMap(Map<String, dynamic> map) {
    return Show(
      id: cmsId(map),
      title: map['title']?.toString() ?? '',
      hawaiianName: map['hawaiian_name'] as String?,
      slug: map['slug']?.toString() ?? '',
      description: map['description'] as String?,
      imageUrl: cmsImageUrl(map['image_url']),
      category: map['category'] as String?,
      watchUrl: map['watch_url'] as String?,
      episodeCount: (map['episode_count'] as num?)?.toInt(),
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
