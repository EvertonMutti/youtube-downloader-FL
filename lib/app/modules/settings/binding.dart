import 'package:get/get.dart';
import 'package:youtube_downloader/app/modules/settings/controller.dart';
import 'package:youtube_downloader/app/modules/settings/core/provider/settings_provider.dart';
import 'package:youtube_downloader/app/modules/settings/repository.dart';

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsRepository>(() => SettingsProvider(), fenix: true);
    Get.lazyPut<SettingsController>(
      () => SettingsController(repository: Get.find()),
      fenix: true,
    );
  }
}
