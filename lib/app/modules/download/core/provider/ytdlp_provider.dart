import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:youtube_downloader/app/core/services/audio_converter_service.dart';
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
    // For audio: use template so yt-dlp picks the real extension (no ffmpeg needed)
    final filePath = streamOption.isAudioOnly
        ? '$outputDirectory/%(title)s.%(ext)s'
        : FileUtils.buildFilePath(outputDirectory, title, 'mp4');
    await FileUtils.ensureDirectoryExists(outputDirectory);

    debugPrint('[YtdlpProvider] downloadVideo: iniciando — videoId=$videoId, isAudio=${streamOption.isAudioOnly}, destino=$filePath');

    final args = [
      if (streamOption.isAudioOnly) ...[
        '-f', 'bestaudio[ext=m4a]/bestaudio',
        '-x',
        // sem --audio-format: evita dependência de ffmpeg
      ],
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
      debugPrint('[YtdlpProvider] downloadVideo: processo iniciado (PID desconhecido)');

      String? actualPath;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint('[YtdlpProvider] downloadVideo stdout: $line');
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isEmpty) return;
        debugPrint('[YtdlpProvider] downloadVideo stderr: $line');
        if (line.startsWith('[download] Destination:')) {
          actualPath = line.replaceFirst('[download] Destination:', '').trim();
        }
        if (line.startsWith('[ffmpeg] Destination:')) {
          // Override with the post-extraction path when yt-dlp uses ffmpeg internally
          actualPath = line.replaceFirst('[ffmpeg] Destination:', '').trim();
        }
        final match = _progressRegex.firstMatch(line);
        if (match != null) {
          final percent = double.tryParse(match.group(1)!) ?? 0;
          onProgress(percent / 100.0);
        }
      });

      Timer? cancelTimer;
      cancelTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (isCancelled()) {
          debugPrint('[YtdlpProvider] downloadVideo: isCancelled=true — enviando SIGTERM ao processo');
          process.kill(ProcessSignal.sigterm);
          cancelTimer?.cancel();
        }
      });

      final exitCode = await process.exitCode;
      cancelTimer.cancel();
      _activeProcess = null;
      debugPrint('[YtdlpProvider] downloadVideo: processo encerrado com exitCode=$exitCode');

      if (isCancelled()) {
        debugPrint('[YtdlpProvider] downloadVideo: CANCELADO — removendo arquivo parcial');
        final target = actualPath ?? filePath;
        final file = File(target);
        if (await file.exists()) await file.delete();
        return DownloadTaskModel(
          status: false,
          detail: 'Download cancelado',
          downloadStatus: DownloadStatus.cancelled,
        );
      }

      if (exitCode != 0) {
        debugPrint('[YtdlpProvider] downloadVideo: ERRO — exitCode=$exitCode');
        return DownloadTaskModel(
          status: false,
          detail: 'Erro no download (codigo $exitCode)',
          downloadStatus: DownloadStatus.error,
        );
      }

      final rawPath = actualPath ?? filePath;
      final savedPath = streamOption.isAudioOnly
          ? await AudioConverterService.convertToMp3(rawPath)
          : rawPath;
      debugPrint('[YtdlpProvider] downloadVideo: CONCLUIDO — salvo em $savedPath');
      return DownloadTaskModel(
        status: true,
        detail: 'Download concluido!',
        videoId: videoId,
        title: title,
        downloadStatus: DownloadStatus.completed,
        progress: 1.0,
        savedPath: savedPath,
      );
    } catch (e) {
      _activeProcess = null;
      debugPrint('[YtdlpProvider] downloadVideo: EXCECAO — $e');
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

    debugPrint('[YtdlpProvider] downloadPlaylist: iniciando — playlistId=$playlistId, audioOnly=$audioOnly, destino=$outputDirectory');

    final outputTemplate = '$outputDirectory/%(title)s.%(ext)s';

    final args = [
      if (audioOnly) ...[
        '-f', 'bestaudio[ext=m4a]/bestaudio',
        '-x',
        // sem --audio-format: evita dependência de ffmpeg
      ],
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
      debugPrint('[YtdlpProvider] downloadPlaylist: processo iniciado');

      int currentItem = 0;
      int totalItems = 0;
      String currentTitle = '';

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint('[YtdlpProvider] downloadPlaylist stdout: $line');
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.trim().isEmpty) return;
        debugPrint('[YtdlpProvider] downloadPlaylist stderr: $line');

        final itemMatch = _itemRegex.firstMatch(line);
        if (itemMatch != null) {
          currentItem = int.parse(itemMatch.group(1)!);
          totalItems = int.parse(itemMatch.group(2)!);
          debugPrint('[YtdlpProvider] downloadPlaylist: item $currentItem/$totalItems — "$currentTitle"');
          onProgress(0.0, currentItem, totalItems, currentTitle);
          return;
        }

        // Capture current video title from "[download] Destination: path/title.ext"
        if (line.startsWith('[download] Destination:')) {
          final dest = line.replaceFirst('[download] Destination:', '').trim();
          final parts = dest.replaceAll('\\', '/').split('/');
          if (parts.isNotEmpty) {
            final fileName = parts.last;
            final dotIndex = fileName.lastIndexOf('.');
            currentTitle = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
            debugPrint('[YtdlpProvider] downloadPlaylist: titulo atual = "$currentTitle"');
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
          debugPrint('[YtdlpProvider] downloadPlaylist: isCancelled=true — enviando SIGTERM ao processo');
          process.kill(ProcessSignal.sigterm);
          cancelTimer?.cancel();
        }
      });

      final exitCode = await process.exitCode;
      cancelTimer.cancel();
      _activeProcess = null;
      debugPrint('[YtdlpProvider] downloadPlaylist: processo encerrado com exitCode=$exitCode');

      if (isCancelled()) {
        debugPrint('[YtdlpProvider] downloadPlaylist: CANCELADO');
        return DownloadTaskModel(
          status: false,
          detail: 'Download cancelado',
          downloadStatus: DownloadStatus.cancelled,
        );
      }

      if (exitCode != 0) {
        debugPrint('[YtdlpProvider] downloadPlaylist: ERRO — exitCode=$exitCode');
        return DownloadTaskModel(
          status: false,
          detail: 'Erro ao baixar playlist (codigo $exitCode)',
          downloadStatus: DownloadStatus.error,
        );
      }

      debugPrint('[YtdlpProvider] downloadPlaylist: CONCLUIDO — $totalItems items processados');
      return DownloadTaskModel(
        status: true,
        detail: 'Playlist baixada com sucesso!',
        downloadStatus: DownloadStatus.completed,
        progress: 1.0,
        totalItems: totalItems,
      );
    } catch (e) {
      _activeProcess = null;
      debugPrint('[YtdlpProvider] downloadPlaylist: EXCECAO — $e');
      return DownloadTaskModel(
        status: false,
        detail: 'Erro ao baixar playlist: $e',
        downloadStatus: DownloadStatus.error,
      );
    }
  }

  @override
  void abortDownload() {
    debugPrint('[YtdlpProvider] abortDownload: enviando SIGTERM ao processo ativo (hasProcess=${_activeProcess != null})');
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
