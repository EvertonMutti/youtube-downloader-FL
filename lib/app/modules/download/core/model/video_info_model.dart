class VideoInfoModel {
  final bool? status;
  final String? detail;
  final String? videoId;
  final String? title;
  final String? author;
  final Duration? duration;
  final String? thumbnailUrl;
  final bool isPlaylist;
  final int? playlistCount;

  VideoInfoModel({
    this.status,
    this.detail,
    this.videoId,
    this.title,
    this.author,
    this.duration,
    this.thumbnailUrl,
    this.isPlaylist = false,
    this.playlistCount,
  });

  String get formattedDuration {
    if (duration == null) return '';
    final h = duration!.inHours;
    final m = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}
