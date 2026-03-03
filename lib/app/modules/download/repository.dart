import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/stream_option_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/video_info_model.dart';

abstract class DownloadRepository {
  Future<VideoInfoModel> getVideoInfo(String url);
  Future<List<StreamOptionModel>> getStreamOptions(String videoId, bool audioOnly);
  Future<DownloadTaskModel> downloadVideo({
    required String videoId,
    required StreamOptionModel streamOption,
    required String outputDirectory,
    required String title,
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  });
  Future<DownloadTaskModel> downloadPlaylist({
    required String playlistId,
    required bool audioOnly,
    required String quality,
    required String outputDirectory,
    required void Function(double progress, int current, int total, String title) onProgress,
    required bool Function() isCancelled,
  });
  void abortDownload();
  void dispose();
}
