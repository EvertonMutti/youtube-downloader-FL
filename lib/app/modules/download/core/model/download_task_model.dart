enum DownloadStatus { idle, fetching, downloading, completed, error, cancelled }

class DownloadTaskModel {
  final bool? status;
  final String? detail;
  final String? videoId;
  final String? title;
  final DownloadStatus downloadStatus;
  final double progress;
  final int currentItem;
  final int totalItems;
  final String? savedPath;

  DownloadTaskModel({
    this.status,
    this.detail,
    this.videoId,
    this.title,
    this.downloadStatus = DownloadStatus.idle,
    this.progress = 0.0,
    this.currentItem = 0,
    this.totalItems = 0,
    this.savedPath,
  });

  DownloadTaskModel copyWith({
    bool? status,
    String? detail,
    String? videoId,
    String? title,
    DownloadStatus? downloadStatus,
    double? progress,
    int? currentItem,
    int? totalItems,
    String? savedPath,
  }) {
    return DownloadTaskModel(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      progress: progress ?? this.progress,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
