import 'dart:io';

import 'package:get/get.dart';
import 'package:youtube_downloader/app/core/services/settings_service.dart';
import 'package:youtube_downloader/app/core/services/ytdlp_service.dart';
import 'package:youtube_downloader/app/modules/download/controller.dart';
import 'package:youtube_downloader/app/modules/download/core/provider/download_provider.dart';
import 'package:youtube_downloader/app/modules/download/core/provider/ytdlp_provider.dart';
import 'package:youtube_downloader/app/modules/download/repository.dart';

class DownloadBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadRepository>(() {
      if (Platform.isAndroid &&
          SettingsService.to.preferYtdlp &&
          YtdlpService.to.isAvailable) {
        return YtdlpProvider();
      }
      return YoutubeExplodeProvider();
    }, fenix: true);
    Get.lazyPut<DownloadController>(
      () => DownloadController(repository: Get.find()),
      fenix: true,
    );
  }
}
