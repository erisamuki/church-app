class Sermon {
  final String id;
  final String title;
  final String speaker;
  final String? series;
  final DateTime date;
  final String? audioUrl;
  final String? videoUrl;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    this.series,
    required this.date,
    this.audioUrl,
    this.videoUrl,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'].toString(),
      title: json['title'] ?? 'Untitled',
      speaker: json['speaker'] ?? 'Unknown',
      series: json['series'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      audioUrl: json['audio_url'],
      videoUrl: json['video_url'],
    );
  }
}
