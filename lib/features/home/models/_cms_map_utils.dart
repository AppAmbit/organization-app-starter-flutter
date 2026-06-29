// Shared CMS map parsing utilities — used by FeedCollection and CollectionItem.

String? _extractId(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is List) return _extractId(value.isNotEmpty ? value.first : null);
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final id = map['id']?.toString() ?? map['entry_id']?.toString();
    if (id != null) return id;
    final data = map['data'];
    if (data is Map) return data['id']?.toString();
    return null;
  }
  return null;
}

String? cmsResolveContentId(Map<String, dynamic> map) {
  // Direct ID field (most common from carousel items)
  final directId = map['content_detail_id'];
  if (directId is String && directId.isNotEmpty) return directId;

  // Relation field (expanded or stub)
  final cdId = _extractId(map['content_detail']);
  if (cdId != null) return cdId;

  // Legacy: 'content' relation
  return _extractId(map['content']);
}

// image_url from platform channel can arrive as String, List, or Map object.
String? _extractImageUrl(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
  if (raw is List) return _extractImageUrl(raw.isNotEmpty ? raw.first : null);
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    for (final key in ['url', 'uri', 'src', 'file_url']) {
      final v = m[key];
      if (v is String && v.isNotEmpty) return v;
    }
    final data = m['data'];
    if (data != null) {
      final fromData = _extractImageUrl(data);
      if (fromData != null) return fromData;
    }
    final file = m['file'];
    if (file is Map) {
      final fileUrl = Map<String, dynamic>.from(file)['url'];
      if (fileUrl is String && fileUrl.isNotEmpty) return fileUrl;
    }
  }
  return null;
}

String? cmsResolveImageUrl(Map<String, dynamic> map) {
  final fromImageUrl = _extractImageUrl(map['image_url']);
  if (fromImageUrl != null) return fromImageUrl;
  return _extractImageUrl(map['image']);
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
