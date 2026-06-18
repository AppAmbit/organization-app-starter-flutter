import 'package:organization_app_starter/core/constants.dart';

class ContentDetailBlock {
  final String id;
  final String type; // ContentBlockType.text | image | video | button
  final String? text;
  final String? buttonUrl;
  final String? buttonText;
  final String? buttonColor;
  final String? bannerImageUrl;
  final String? bannerVideoUrl;

  const ContentDetailBlock({
    required this.id,
    required this.type,
    this.text,
    this.buttonUrl,
    this.buttonText,
    this.buttonColor,
    this.bannerImageUrl,
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
      bannerVideoUrl: map['banner_video']?.toString(),
    );
  }
}

class ContentDetail {
  final String id;
  final String? title;
  final List<ContentDetailBlock> contentBlocks;

  const ContentDetail({
    required this.id,
    this.title,
    required this.contentBlocks,
  });

  factory ContentDetail.fromMap(Map<String, dynamic> map) {
    final blocksRaw = map['content'];
    List<ContentDetailBlock> blocks = [];
    
    if (blocksRaw is List) {
      for (final raw in blocksRaw) {
        if (raw is Map) {
          blocks.add(ContentDetailBlock.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return ContentDetail(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString(),
      contentBlocks: blocks,
    );
  }
}
