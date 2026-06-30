import 'package:organization_app_starter/shared/domain/cms_parse.dart';

/// A browse genre / program category (maps to the `categories` CMS type).
class Category {
  final String id;
  final String name;
  final String? hawaiianName;
  final String slug;
  final String? imageUrl;
  final String? description;
  final int displayOrder;

  const Category({
    required this.id,
    required this.name,
    this.hawaiianName,
    required this.slug,
    this.imageUrl,
    this.description,
    required this.displayOrder,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: cmsId(map),
      name: map['name']?.toString() ?? '',
      hawaiianName: map['hawaiian_name'] as String?,
      slug: map['slug']?.toString() ?? '',
      imageUrl: cmsImageUrl(map['image_url']),
      description: map['description'] as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
