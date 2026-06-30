class LiveChannel {
  final String id;
  final String name;

  const LiveChannel({required this.id, required this.name});
}

class LiveProgram {
  final String id;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String? season;
  final String? episode;
  final String? rating;
  final String? duration;

  const LiveProgram({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    this.season,
    this.episode,
    this.rating,
    this.duration,
  });

  String get metadataLine {
    final parts = <String>[];
    if (season != null) parts.add('Season $season');
    if (episode != null) parts.add('Episode $episode');
    if (rating != null) parts.add(rating!);
    if (duration != null) parts.add(duration!);
    return parts.join('  •  ');
  }
}
