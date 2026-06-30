import 'package:organization_app_starter/shared/domain/cms_parse.dart';

/// A scheduled program slot on a live channel.
class LiveSlot {
  final String time;
  final String title;
  final String? series;
  final String? note;

  const LiveSlot({
    required this.time,
    required this.title,
    this.series,
    this.note,
  });

  factory LiveSlot.fromMap(Map<String, dynamic> map) {
    return LiveSlot(
      time: map['time']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      series: map['series'] as String?,
      note: map['note'] as String?,
    );
  }
}

/// A live TV channel (maps to the `live_channels` CMS type).
class LiveChannel {
  final String id;
  final String name;
  final String? hawaiianTagline;
  final String? description;
  final String? channelNumber;
  final String? watchUrl;
  final String? imageUrl;
  final List<LiveSlot> schedule;

  const LiveChannel({
    required this.id,
    required this.name,
    this.hawaiianTagline,
    this.description,
    this.channelNumber,
    this.watchUrl,
    this.imageUrl,
    this.schedule = const [],
  });

  factory LiveChannel.fromMap(Map<String, dynamic> map) {
    return LiveChannel(
      id: cmsId(map),
      name: map['name']?.toString() ?? '',
      hawaiianTagline: map['hawaiian_tagline'] as String?,
      description: map['description'] as String?,
      channelNumber: map['channel_number'] as String?,
      watchUrl: map['watch_url'] as String?,
      imageUrl: cmsImageUrl(map['image_url']),
      schedule: cmsMapList(map['schedule']).map(LiveSlot.fromMap).toList(),
    );
  }
}
