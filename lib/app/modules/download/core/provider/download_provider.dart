import 'dart:async';
import 'dart:io';

import 'package:youtube_downloader/app/core/utils/file_utils.dart';
import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/stream_option_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/video_info_model.dart';
import 'package:youtube_downloader/app/modules/download/repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeExplodeProvider implements DownloadRepository {
  YoutubeExplode _yt = YoutubeExplode();
  StreamManifest? _cachedManifest;
  String? _cachedManifestVideoId;

  @override
  Future<VideoInfoModel> getVideoInfo(String url) async {
    try {
      final trimmed = url.trim();

      // Check if it is a playlist URL
      if (_isPlaylistUrl(trimmed)) {
        final playlistId = PlaylistId.parsePlaylistId(trimmed);
        if (playlistId == null) {
          return VideoInfoModel(
            status: false,
            detail: 'URL de playlist invalida. Verifique o link e tente novamente.',
          );
        }
        final playlist = await _yt.playlists.get(playlistId);
        int count = 0;
        await for (final _ in _yt.playlists.getVideos(playlistId)) {
          count++;
        }
        return VideoInfoModel(
          status: true,
          videoId: playlistId,
          title: playlist.title,
          author: playlist.author,
          isPlaylist: true,
          playlistCount: count,
        );
      }

      // Single video
      final videoId = VideoId.parseVideoId(trimmed);
      if (videoId == null) {
        return VideoInfoModel(
          status: false,
          detail: 'URL invalida. Verifique o link do YouTube e tente novamente.',
        );
      }
      final video = await _yt.videos.get(videoId);
      return VideoInfoModel(
        status: true,
        videoId: videoId,
        title: video.title,
        author: video.author,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
        isPlaylist: false,
      );
    } catch (e) {
      return VideoInfoModel(
        status: false,
        detail: 'Erro ao buscar informacoes: ${_friendlyError(e)}',
      );
    }
  }

  @override
  Future<List<StreamOptionModel>> getStreamOptions(String videoId, bool audioOnly) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.tv, YoutubeApiClient.android],
      );
      _cachedManifest = manifest;
      _cachedManifestVideoId = videoId;
      final options = <StreamOptionModel>[];

      if (audioOnly) {
        final audioStreams = manifest.audioOnly.toList()
          ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

        for (final s in audioStreams) {
          final kbps = (s.bitrate.bitsPerSecond / 1000).round();
          options.add(StreamOptionModel(
            status: true,
            label: '${kbps}kbps (${s.audioCodec})',
            tag: s.tag.toString(),
            isAudioOnly: true,
            bitrate: s.bitrate.bitsPerSecond,
            container: s.container.name,
          ));
        }
      } else {
        final muxedStreams = manifest.muxed.toList()
          ..sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));

        for (final s in muxedStreams) {
          options.add(StreamOptionModel(
            status: true,
            label: '${s.qualityLabel} (${s.container.name})',
            tag: s.tag.toString(),
            isAudioOnly: false,
            container: s.container.name,
          ));
        }
      }

      if (options.isEmpty) {
        return [
          StreamOptionModel(
            status: false,
            detail: 'Nenhuma stream disponivel',
            label: 'Indisponivel',
            tag: '',
            isAudioOnly: audioOnly,
          )
        ];
      }

      return options;
    } catch (e) {
      return [
        StreamOptionModel(
          status: false,
          detail: 'Erro ao buscar qualidades: ${_friendlyError(e)}',
          label: 'Erro',
          tag: '',
          isAudioOnly: audioOnly,
        )
      ];
    }
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
    try {
      final manifest = (_cachedManifestVideoId == videoId && _cachedManifest != null)
          ? _cachedManifest!
          : await _yt.videos.streamsClient.getManifest(
              videoId,
              ytClients: [YoutubeApiClient.tv, YoutubeApiClient.android],
            );
      final StreamInfo streamInfo;

      if (streamOption.isAudioOnly) {
        final tag = int.tryParse(streamOption.tag);
        streamInfo = manifest.audioOnly.firstWhere(
          (s) => s.tag == tag,
          orElse: () => manifest.audioOnly.withHighestBitrate(),
        );
      } else {
        final tag = int.tryParse(streamOption.tag);
        streamInfo = manifest.muxed.firstWhere(
          (s) => s.tag == tag,
          orElse: () => manifest.muxed.withHighestBitrate(),
        );
      }

      final ext = streamOption.isAudioOnly ? 'mp3' : streamOption.container ?? 'mp4';
      final filePath = FileUtils.buildFilePath(outputDirectory, title, ext);
      await FileUtils.ensureDirectoryExists(outputDirectory);

      final file = File(filePath);
      final sink = file.openWrite();

      try {
        final stream = _yt.videos.streamsClient.get(streamInfo);
        final totalBytes = streamInfo.size.totalBytes;
        int received = 0;

        bool cancelled = false;
        await for (final chunk in stream) {
          if (isCancelled()) {
            cancelled = true;
            break;
          }
          sink.add(chunk);
          received += chunk.length;
          if (totalBytes > 0) {
            onProgress(received / totalBytes);
          }
        }

        await sink.flush();
        await sink.close();

        if (cancelled || isCancelled()) {
          if (await file.exists()) await file.delete();
          return DownloadTaskModel(
            status: false,
            detail: 'Download cancelado',
            downloadStatus: DownloadStatus.cancelled,
          );
        }
      } catch (e) {
        await sink.close();
        if (await file.exists()) await file.delete();
        rethrow;
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
      return DownloadTaskModel(
        status: false,
        detail: 'Erro no download: ${_friendlyError(e)}',
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
    try {
      final videos = await _yt.playlists.getVideos(playlistId).toList();
      final total = videos.length;

      if (total == 0) {
        return DownloadTaskModel(
          status: false,
          detail: 'Playlist vazia ou inacessivel',
          downloadStatus: DownloadStatus.error,
        );
      }

      await FileUtils.ensureDirectoryExists(outputDirectory);

      for (var i = 0; i < total; i++) {
        if (isCancelled()) {
          return DownloadTaskModel(
            status: false,
            detail: 'Download cancelado',
            downloadStatus: DownloadStatus.cancelled,
          );
        }

        final video = videos[i];
        onProgress(0.0, i + 1, total, video.title);

        // Per-video timeout: if this video stalls for 90s, abort and skip it
        final videoTimer = Timer(const Duration(seconds: 90), () {
          _yt.close();
          _yt = YoutubeExplode();
        });

        try {
          final manifest = await _yt.videos.streamsClient.getManifest(
            video.id,
            ytClients: [YoutubeApiClient.tv, YoutubeApiClient.android],
          );
          StreamInfo streamInfo;

          if (audioOnly) {
            streamInfo = manifest.audioOnly.withHighestBitrate();
          } else {
            streamInfo = manifest.muxed.withHighestBitrate();
          }

          final ext = audioOnly ? 'mp3' : 'mp4';
          final filePath = FileUtils.buildFilePath(outputDirectory, video.title, ext);
          final file = File(filePath);
          final sink = file.openWrite();

          try {
            final stream = _yt.videos.streamsClient.get(streamInfo);
            final totalBytes = streamInfo.size.totalBytes;
            int received = 0;

            await for (final chunk in stream) {
              if (isCancelled()) break;
              sink.add(chunk);
              received += chunk.length;
              if (totalBytes > 0) {
                onProgress(received / totalBytes, i + 1, total, video.title);
              }
            }

            await sink.flush();
            await sink.close();
          } catch (_) {
            await sink.close();
            if (await file.exists()) await file.delete();
          }
        } catch (_) {
          // Skip failed/timed-out video, continue with the rest
        } finally {
          videoTimer.cancel();
        }
      }

      return DownloadTaskModel(
        status: true,
        detail: 'Playlist baixada com sucesso!',
        downloadStatus: DownloadStatus.completed,
        progress: 1.0,
        totalItems: total,
      );
    } catch (e) {
      return DownloadTaskModel(
        status: false,
        detail: 'Erro ao baixar playlist: ${_friendlyError(e)}',
        downloadStatus: DownloadStatus.error,
      );
    }
  }

  @override
  void abortDownload() {
    // Closing _yt aborts any pending HTTP request inside the stream loop,
    // which throws HttpClientClosedException and breaks the while loop.
    _yt.close();
    _yt = YoutubeExplode();
    _cachedManifest = null;
    _cachedManifestVideoId = null;
  }

  @override
  void dispose() {
    _yt.close();
  }

  bool _isPlaylistUrl(String url) {
    // If URL has a video ID, treat as single video regardless of list= param
    // (e.g. watch?v=...&list=RD... are radio/mix sessions, not downloadable playlists)
    if (url.contains('v=')) return false;
    return url.contains('list=') || url.contains('playlist?');
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timeout')) {
      return 'Tempo limite excedido. O YouTube pode estar bloqueando a requisicao. Tente novamente.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Sem conexao com a internet';
    }
    if (msg.contains('VideoUnplayableException') || msg.contains('unavailable')) {
      return 'Video indisponivel ou privado';
    }
    if (msg.contains('VideoRequiresLoginException')) {
      return 'Video requer login';
    }
    if (msg.length > 120) return msg.substring(0, 120);
    return msg;
  }
}
