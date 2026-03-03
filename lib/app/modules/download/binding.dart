import 'package:flutter/foundation.dart';
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
      final preferYtdlp = SettingsService.to.preferYtdlp;
      final ytdlpAvailable = YtdlpService.to.isAvailable;
      if (preferYtdlp && ytdlpAvailable) {
        debugPrint('[Binding] Provider selecionado: YtdlpProvider (preferYtdlp=$preferYtdlp, isAvailable=$ytdlpAvailable)');
        return YtdlpProvider();
      }
      debugPrint('[Binding] Provider selecionado: YoutubeExplodeProvider (preferYtdlp=$preferYtdlp, ytdlpAvailable=$ytdlpAvailable)');
      return YoutubeExplodeProvider();
    }, fenix: true);
    Get.lazyPut<DownloadController>(
      () => DownloadController(repository: Get.find()),
      fenix: true,
    );
  }
}
