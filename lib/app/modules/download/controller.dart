import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/core/enums/download_type.dart';
import 'package:youtube_downloader/app/core/services/settings_service.dart';
import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/stream_option_model.dart';
import 'package:youtube_downloader/app/modules/download/core/model/video_info_model.dart';
import 'package:youtube_downloader/app/modules/download/repository.dart';

class DownloadController extends GetxController {
  final DownloadRepository repository;

  DownloadController({required this.repository});

  final TextEditingController urlController = TextEditingController();

  final RxBool fetching = false.obs;
  final RxBool loadingOptions = false.obs;
  final RxBool downloading = false.obs;
  final RxBool audioOnly = false.obs;

  bool _cancelRequested = false;

  final Rx<VideoInfoModel?> videoInfo = Rx<VideoInfoModel?>(null);
  final RxList<StreamOptionModel> streamOptions = <StreamOptionModel>[].obs;
  final Rx<StreamOptionModel?> selectedOption = Rx<StreamOptionModel?>(null);
  final Rx<DownloadTaskModel?> currentTask = Rx<DownloadTaskModel?>(null);

  bool get getFetching => fetching.value;
  bool get getLoadingOptions => loadingOptions.value;
  bool get getDownloading => downloading.value;
  bool get getAudioOnly => audioOnly.value;
  VideoInfoModel? get getVideoInfo => videoInfo.value;
  List<StreamOptionModel> get getStreamOptions => streamOptions;
  StreamOptionModel? get getSelectedOption => selectedOption.value;
  DownloadTaskModel? get getCurrentTask => currentTask.value;

  set setFetching(bool v) => fetching.value = v;
  set setLoadingOptions(bool v) => loadingOptions.value = v;
  set setDownloading(bool v) => downloading.value = v;

  void cancelDownload() {
    debugPrint('[DownloadCtrl] cancelDownload: solicitacao de cancelamento enviada');
    _cancelRequested = true;
    repository.abortDownload(); // closes HTTP client → breaks the internal stream loop
  }

  @override
  void onClose() {
    urlController.dispose();
    repository.dispose();
    super.onClose();
  }

  Future<void> fetchInfo() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        AppStrings.snackWarning,
        AppStrings.msgNoUrl,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textPrimary,
      );
      return;
    }

    setFetching = true;
    videoInfo.value = null;
    streamOptions.clear();
    selectedOption.value = null;
    currentTask.value = null;

    final result = await repository.getVideoInfo(url);
    setFetching = false;

    if (result.status != true) {
      Get.snackbar(
        AppStrings.snackError,
        result.detail ?? AppStrings.msgVideoInfoError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    videoInfo.value = result;

    // Apply default type from settings
    audioOnly.value = SettingsService.to.defaultType == DownloadType.audio;

    await _loadStreamOptions();
  }

  Future<void> _loadStreamOptions() async {
    final info = videoInfo.value;
    if (info == null || info.videoId == null) return;
    if (info.isPlaylist) return; // Playlist uses best quality auto

    setLoadingOptions = true;
    final options = await repository.getStreamOptions(info.videoId!, audioOnly.value);
    setLoadingOptions = false;

    streamOptions.value = options;

    // Pre-select best option matching default quality preference
    if (options.isNotEmpty && options.first.status == true) {
      selectedOption.value = options.first;
    }
  }

  Future<void> onTypeChanged(bool isAudioOnly) async {
    if (audioOnly.value == isAudioOnly) return;
    audioOnly.value = isAudioOnly;
    streamOptions.clear();
    selectedOption.value = null;
    await _loadStreamOptions();
  }

  void onQualityChanged(StreamOptionModel? option) {
    selectedOption.value = option;
  }

  Future<void> startDownload() async {
    if (downloading.value) return;

    final info = videoInfo.value;
    if (info == null) {
      Get.snackbar(
        AppStrings.snackWarning,
        AppStrings.msgNoVideoInfo,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textPrimary,
      );
      return;
    }

    // Request storage permission on Android
    if (Platform.isAndroid) {
      final granted = await _requestStoragePermission();
      if (!granted) return;
    }

    final outputDir = SettingsService.to.downloadPath;
    _cancelRequested = false;
    setDownloading = true;

    debugPrint('[DownloadCtrl] startDownload: tipo=${info.isPlaylist ? "playlist" : "video"}, id=${info.videoId}, destino=$outputDir');

    // Auto-abort if download takes more than 5 minutes
    final abortTimer = Timer(const Duration(minutes: 5), () {
      debugPrint('[DownloadCtrl] startDownload: TIMEOUT de 5 min atingido — abortando');
      cancelDownload();
    });

    try {
      if (info.isPlaylist) {
        await _downloadPlaylist(info, outputDir);
      } else {
        await _downloadSingleVideo(info, outputDir);
      }
    } finally {
      abortTimer.cancel();
      _cancelRequested = false;
      setDownloading = false;
      debugPrint('[DownloadCtrl] startDownload: finally — downloading=false');
    }
  }

  Future<void> _downloadSingleVideo(VideoInfoModel info, String outputDir) async {
    final option = selectedOption.value;
    if (option == null || option.tag.isEmpty) {
      Get.snackbar(
        AppStrings.snackWarning,
        AppStrings.msgSelectQuality,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textPrimary,
      );
      setDownloading = false;
      return;
    }

    debugPrint('[DownloadCtrl] _downloadSingleVideo: iniciando — videoId=${info.videoId}, isAudio=${option.isAudioOnly}, tag=${option.tag}');

    currentTask.value = DownloadTaskModel(
      title: info.title,
      videoId: info.videoId,
      downloadStatus: DownloadStatus.downloading,
      progress: 0.0,
    );

    final result = await repository.downloadVideo(
      videoId: info.videoId!,
      streamOption: option,
      outputDirectory: outputDir,
      title: info.title ?? AppStrings.labelVideo,
      onProgress: (progress) {
        currentTask.value = currentTask.value?.copyWith(
          progress: progress,
          downloadStatus: DownloadStatus.downloading,
        );
      },
      isCancelled: () => _cancelRequested,
    );

    debugPrint('[DownloadCtrl] _downloadSingleVideo: resultado=${result.downloadStatus}, detail=${result.detail}');
    currentTask.value = result;

    if (result.downloadStatus == DownloadStatus.cancelled) {
      debugPrint('[DownloadCtrl] _downloadSingleVideo: CANCELADO pelo usuario');
      // No snackbar needed — the UI already updates to cancelled state
    } else if (result.status == true) {
      Get.snackbar(
        AppStrings.snackSuccess,
        '${AppStrings.msgVideoDownloadedPrefix}$outputDir',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        AppStrings.snackError,
        result.detail ?? AppStrings.msgDownloadError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> _downloadPlaylist(VideoInfoModel info, String outputDir) async {
    debugPrint('[DownloadCtrl] _downloadPlaylist: iniciando — playlistId=${info.videoId}, total=${info.playlistCount}, audioOnly=${audioOnly.value}');

    currentTask.value = DownloadTaskModel(
      title: info.title,
      downloadStatus: DownloadStatus.downloading,
      progress: 0.0,
      totalItems: info.playlistCount ?? 0,
    );

    final result = await repository.downloadPlaylist(
      playlistId: info.videoId!,
      audioOnly: audioOnly.value,
      quality: SettingsService.to.defaultQuality.value,
      outputDirectory: outputDir,
      isCancelled: () => _cancelRequested,
      onProgress: (progress, current, total, title) {
        currentTask.value = DownloadTaskModel(
          title: title,
          downloadStatus: DownloadStatus.downloading,
          progress: progress,
          currentItem: current,
          totalItems: total,
        );
      },
    );

    debugPrint('[DownloadCtrl] _downloadPlaylist: resultado=${result.downloadStatus}, detail=${result.detail}');
    currentTask.value = result;

    if (result.downloadStatus == DownloadStatus.cancelled) {
      debugPrint('[DownloadCtrl] _downloadPlaylist: CANCELADO pelo usuario');
      // No snackbar needed — the UI already updates to cancelled state
    } else if (result.status == true) {
      Get.snackbar(
        AppStrings.snackSuccess,
        '${AppStrings.msgPlaylistDownloadedPrefix}$outputDir',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        AppStrings.snackError,
        result.detail ?? AppStrings.msgPlaylistDownloadError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try manage external storage first (Android 11+)
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return true;

      final manageResult = await Permission.manageExternalStorage.request();
      if (manageResult.isGranted) return true;

      // Fall back to regular storage permission
      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted) return true;

      Get.snackbar(
        AppStrings.snackPermissionDenied,
        AppStrings.msgPermissionDenied,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textPrimary,
      );
      return false;
    }
    return true;
  }
}
