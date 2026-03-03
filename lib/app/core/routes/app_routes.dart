import 'package:get/get.dart';
import 'package:youtube_downloader/app/modules/download/binding.dart';
import 'package:youtube_downloader/app/modules/download/page.dart';
import 'package:youtube_downloader/app/modules/settings/binding.dart';
import 'package:youtube_downloader/app/modules/settings/page.dart';

abstract class Routes {
  Routes._();

  static const download = '/';
  static const settings = '/settings';
}

class AppPages {
  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: Routes.download,
      page: () => const DownloadPage(),
      binding: DownloadBinding(),
      title: 'YouTube Downloader',
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      title: 'Configuracoes',
    ),
  ];
}
