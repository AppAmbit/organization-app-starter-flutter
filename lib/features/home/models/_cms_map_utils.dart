// Shared CMS map parsing utilities — used by FeedCollection and CollectionItem.

String? cmsResolveContentId(Map<String, dynamic> map) {
  final content = map['content'];
  if (content is Map) return content['id']?.toString();
  if (content is String) return content;
  final contentDetail = map['content_detail'];
  if (contentDetail is Map) return contentDetail['id']?.toString();
  if (contentDetail is String) return contentDetail;
  return null;
}

String? cmsResolveImageUrl(Map<String, dynamic> map) {
  final resolvedUrl = map['image_url'];
  if (resolvedUrl is String && resolvedUrl.isNotEmpty) return resolvedUrl;
  final raw = map['image'];
  if (raw is String && raw.isNotEmpty) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  }
  return null;
}

bool cmsParseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

// Returns a guaranteed-unique fallback when CMS record has no id or lookup_key.
String cmsFallbackId(Map<String, dynamic> map) {
  return map['id']?.toString() ??
      map['lookup_key']?.toString() ??
      'cms_${DateTime.now().microsecondsSinceEpoch}';
}
