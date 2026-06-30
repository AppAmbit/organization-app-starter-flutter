// Shared CMS parsing helpers for models outside the home feature.
//
// CMS responses arrive through a platform channel, so fields can be String,
// List, or Map. These helpers normalize the common cases.

/// Resolves an image URL that may arrive as a String, a List, or a Map object.
String? cmsImageUrl(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
  if (raw is List) return cmsImageUrl(raw.isNotEmpty ? raw.first : null);
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    for (final key in ['url', 'uri', 'src', 'file_url']) {
      final v = m[key];
      if (v is String && v.isNotEmpty) return v;
    }
    final data = m['data'];
    if (data != null) return cmsImageUrl(data);
  }
  return null;
}

/// Returns a stable id for a CMS record, falling back to lookup/slug.
String cmsId(Map<String, dynamic> map) {
  return map['id']?.toString() ??
      map['slug']?.toString() ??
      map['lookup_key']?.toString() ??
      'cms_${DateTime.now().microsecondsSinceEpoch}';
}

/// Parses a JSON-ish list field that may arrive as a List of Maps.
List<Map<String, dynamic>> cmsMapList(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}
