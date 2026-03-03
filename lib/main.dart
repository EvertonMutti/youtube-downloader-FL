import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/app/core/routes/app_routes.dart';
import 'package:youtube_downloader/app/core/services/settings_service.dart';
import 'package:youtube_downloader/app/core/services/ytdlp_service.dart';
import 'package:youtube_downloader/app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync<SettingsService>(() async {
    final service = SettingsService();
    await service.init();
    return service;
  });

  await Get.putAsync<YtdlpService>(() async {
    final service = YtdlpService();
    await service.init();
    return service;
  });

  runApp(const YouTubeDownloaderApp());
}

class YouTubeDownloaderApp extends StatelessWidget {
  const YouTubeDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'YouTube Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: Routes.download,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
