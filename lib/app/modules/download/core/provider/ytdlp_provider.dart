import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:youtube_downloader/app/core/services/ytdlp_service.dart';
import 'package:youtube_downloader/app/core/utils/file_utils.dart';
import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/stream_option_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/video_info_model.dart';
import 'package:youtube_downloader/app/modules/download/repository.dart';

class YtdlpProvider implements DownloadRepository {
  Process? _activeProcess;

  static const _ytWatchBase = 'https://www.youtube.com/watch?v=';
  static const _ytPlaylistBase = 'https://www.youtube.com/playlist?list=';

  // Matches: [download]  12.3% of ...
  static final _progressRegex = RegExp(r'\[download\]\s+([\d.]+)%');
  // Matches: [download] Downloading item 1 of 10
  static final _itemRegex = RegExp(r'\[download\] Downloading item (\d+) of (\d+)');

  @override
  Future<VideoInfoModel> getVideoInfo(String url) async {
    final trimmed = url.trim();
    final isPlaylist = trimmed.contains('list=') && !trimmed.contains('v=');

    try {
      if (isPlaylist) {
        // Count videos and get playlist title via flat listing
        final result = await Process.run(YtdlpService.to.binaryPath, [
          '--flat-playlist',
          '--print',
          '%(playlist_title)s\t%(id)s',
          '--no-warnings',
          trimmed,
        ]);
        if (result.exitCode != 0) {
          return VideoInfoModel(
            status: false,
            detail: 'Erro ao buscar playlist: ${result.stderr}',
          );
        }
        final lines = (result.stdout as String)
            .trim()
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        if (lines.isEmpty) {
          return VideoInfoModel(status: false, detail: 'Playlist vazia ou inacessivel');
        }
        final firstParts = lines.first.split('\t');
        final playlistTitle = firstParts.isNotEmpty ? firstParts.first.trim() : 'Playlist';
        final playlistId = _extractPlaylistId(trimmed);
        return VideoInfoModel(
          status: true,
          videoId: playlistId ?? trimmed,
          title: playlistTitle,
          isPlaylist: true,
          playlistCount: lines.length,
        );
      } else {
        // Single video
        final result = await Process.run(YtdlpService.to.binaryPath, [
          '--no-playlist',
          '-j',
          '--no-warnings',
          trimmed,
        ]);
        if (result.exitCode != 0) {
          return VideoInfoModel(
            status: false,
            detail: 'Erro ao buscar video: ${result.stderr}',
          );
        }
        final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
        final durationSecs = (json['duration'] as num?)?.toInt();
        return VideoInfoModel(
          status: true,
          videoId: json['id'] as String?,
          title: json['title'] as String?,
          author: json['uploader'] as String?,
          thumbnailUrl: json['thumbnail'] as String?,
          duration: durationSecs != null ? Duration(seconds: durationSecs) : null,
          isPlaylist: false,
        );
      }
    } catch (e) {
      return VideoInfoModel(status: false, detail: 'Erro ao buscar informacoes: $e');
    }
  }

  @override
  Future<List<StreamOptionModel>> getStreamOptions(String videoId, bool audioOnly) async {
    // yt-dlp selects format automatically; expose a single synthetic option
    return [
      StreamOptionModel(
        status: true,
        label: audioOnly ? 'Melhor audio (yt-dlp)' : 'Melhor video (yt-dlp)',
        tag: audioOnly ? 'bestaudio' : 'bestvideo+bestaudio/best',
        isAudioOnly: audioOnly,
      ),
    ];
  }

  @override
  Future<DownloadTaskModel> downloadVideo({
    required String videoId,
    required StreamOptionModel streamOption,
    required String outputDirectory,
    required String title,
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  }) async {
    final url = '$_ytWatchBase$videoId';
    final ext = streamOption.isAudioOnly ? 'mp3' : 'mp4';
    final filePath = FileUtils.buildFilePath(outputDirectory, title, ext);
    await FileUtils.ensureDirectoryExists(outputDirectory);

    final args = [
      if (streamOption.isAudioOnly) ...['-x', '--audio-format', 'mp3'],
      if (!streamOption.isAudioOnly) ...[
        '-f',
        'bestvideo+bestaudio/best',
        '--merge-output-format',
        'mp4',
      ],
      '--progress',
      '--newline',
      '--no-warnings',
      '-o',
      filePath,
      url,
    ];

    try {
      final process = await Process.start(YtdlpService.to.binaryPath, args);
      _activeProcess = process;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final match = _progressRegex.firstMatch(line);
        if (match != null) {
          final percent = double.tryParse(match.group(1)!) ?? 0;
          onProgress(percent / 100.0);
        }
      });

      Timer? cancelTimer;
      cancelTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (isCancelled()) {
          process.kill(ProcessSignal.sigterm);
          cancelTimer?.cancel();
        }
      });

      final exitCode = await process.exitCode;
      cancelTimer.cancel();
      _activeProcess = null;

      if (isCancelled()) {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
        return DownloadTaskModel(
          status: false,
          detail: 'Download cancelado',
          downloadStatus: DownloadStatus.cancelled,
        );
      }

      if (exitCode != 0) {
        return DownloadTaskModel(
          status: false,
          detail: 'Erro no download (codigo $exitCode)',
          downloadStatus: DownloadStatus.error,
        );
      }

      return DownloadTaskModel(
        status: true,
        detail: 'Download concluido!',
        videoId: videoId,
        title: title,
        downloadStatus: DownloadStatus.completed,
        progress: 1.0,
        savedPath: filePath,
      );
    } catch (e) {
      _activeProcess = null;
      return DownloadTaskModel(
        status: false,
        detail: 'Erro no download: $e',
        downloadStatus: DownloadStatus.error,
      );
    }
  }

  @override
  Future<DownloadTaskModel> downloadPlaylist({
    required String playlistId,
    required bool audioOnly,
    required String quality,
    required String outputDirectory,
    required void Function(double progress, int current, int total, String title) onProgress,
    required bool Function() isCancelled,
  }) async {
    final url = '$_ytPlaylistBase$playlistId';
    await FileUtils.ensureDirectoryExists(outputDirectory);

    final outputTemplate = '$outputDirectory/%(title)s.%(ext)s';

    final args = [
      if (audioOnly) ...['-x', '--audio-format', 'mp3'],
      if (!audioOnly) ...[
        '-f',
        'bestvideo+bestaudio/best',
        '--merge-output-format',
        'mp4',
      ],
      '--progress',
      '--newline',
      '--no-warnings',
      '-o',
      outputTemplate,
      url,
    ];

    try {
      final process = await Process.start(YtdlpService.to.binaryPath, args);
      _activeProcess = process;

      int currentItem = 0;
      int totalItems = 0;
      String currentTitle = '';

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final itemMatch = _itemRegex.firstMatch(line);
        if (itemMatch != null) {
          currentItem = int.parse(itemMatch.group(1)!);
          totalItems = int.parse(itemMatch.group(2)!);
          onProgress(0.0, currentItem, totalItems, currentTitle);
          return;
        }

        // Capture current video title from yt-dlp output
        // "[youtube] <id>: Downloading..."  or "[download] Destination: path/title.ext"
        if (line.startsWith('[download] Destination:')) {
          final parts = line.split('/');
          if (parts.isNotEmpty) {
            final fileName = parts.last;
            final dotIndex = fileName.lastIndexOf('.');
            currentTitle = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
          }
        }

        final progressMatch = _progressRegex.firstMatch(line);
        if (progressMatch != null) {
          final percent = double.tryParse(progressMatch.group(1)!) ?? 0;
          onProgress(percent / 100.0, currentItem, totalItems, currentTitle);
        }
      });

      Timer? cancelTimer;
      cancelTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (isCancelled()) {
          process.kill(ProcessSignal.sigterm);
          cancelTimer?.cancel();
        }
      });

      final exitCode = await process.exitCode;
      cancelTimer.cancel();
      _activeProcess = null;

      if (isCancelled()) {
        return DownloadTaskModel(
          status: false,
          detail: 'Download cancelado',
          downloadStatus: DownloadStatus.cancelled,
        );
      }

      if (exitCode != 0) {
        return DownloadTaskModel(
          status: false,
          detail: 'Erro ao baixar playlist (codigo $exitCode)',
          downloadStatus: DownloadStatus.error,
        );
      }

      return DownloadTaskModel(
        status: true,
        detail: 'Playlist baixada com sucesso!',
        downloadStatus: DownloadStatus.completed,
        progress: 1.0,
        totalItems: totalItems,
      );
    } catch (e) {
      _activeProcess = null;
      return DownloadTaskModel(
        status: false,
        detail: 'Erro ao baixar playlist: $e',
        downloadStatus: DownloadStatus.error,
      );
    }
  }

  @override
  void abortDownload() {
    _activeProcess?.kill(ProcessSignal.sigterm);
    _activeProcess = null;
  }

  @override
  void dispose() {
    abortDownload();
  }

  String? _extractPlaylistId(String url) {
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['list'];
  }
}
