import 'package:organization_app_starter/core/constants.dart';

class ContentDetailBlock {
  final String id;
  final String type; // ContentBlockType.text | image | video | button
  final String? text;
  final String? buttonUrl;
  final String? buttonText;
  final String? buttonColor;
  final String? bannerImageUrl;
  final String? bannerImage;
  final String? bannerVideoUrl;

  const ContentDetailBlock({
    required this.id,
    required this.type,
    this.text,
    this.buttonUrl,
    this.buttonText,
    this.buttonColor,
    this.bannerImageUrl,
    this.bannerImage,
    this.bannerVideoUrl,
  });

  factory ContentDetailBlock.fromMap(Map<String, dynamic> map) {
    return ContentDetailBlock(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? ContentBlockType.text,
      text: map['text']?.toString(),
      buttonUrl: map['button_url']?.toString(),
      buttonText: map['button_text']?.toString(),
      buttonColor: map['button_color']?.toString(),
      bannerImageUrl: map['banner_image_url']?.toString(),
      bannerImage: map['banner_image']?.toString(),
      bannerVideoUrl: map['banner_video']?.toString(),
    );
  }
}

bool _isRelationStub(Map<String, dynamic> map) {
  if (map.containsKey('type')) return false;
  final keys = map.keys;
  return keys.length <= 2 && (keys.contains('id') || keys.contains('entry_id'));
}

class ContentDetail {
  final String id;
  final String? title;
  final List<ContentDetailBlock> contentBlocks;
  final List<String> unresolvedContentIds;

  const ContentDetail({
    required this.id,
    this.title,
    required this.contentBlocks,
    this.unresolvedContentIds = const [],
  });

  factory ContentDetail.fromMap(Map<String, dynamic> map) {
    final blocksRaw = map['content'];
    final blocks = <ContentDetailBlock>[];
    final unresolvedIds = <String>[];

    if (blocksRaw is List) {
      for (final raw in blocksRaw) {
        if (raw is Map) {
          final cast = Map<String, dynamic>.from(raw);
          if (_isRelationStub(cast)) {
            final eid = cast['entry_id']?.toString() ?? cast['id']?.toString();
            if (eid != null && eid.isNotEmpty) unresolvedIds.add(eid);
          } else {
            blocks.add(ContentDetailBlock.fromMap(cast));
          }
        } else if (raw is String && raw.isNotEmpty) {
          unresolvedIds.add(raw);
        }
      }
    }

    return ContentDetail(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString(),
      contentBlocks: blocks,
      unresolvedContentIds: unresolvedIds,
    );
  }
}
