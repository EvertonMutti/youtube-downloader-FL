import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/core/services/settings_service.dart';
import 'package:youtube_downloader/app/modules/settings/core/model/settings_model.dart';
import 'package:youtube_downloader/app/modules/settings/repository.dart';

class SettingsProvider implements SettingsRepository {
  @override
  Future<SettingsModel> loadSettings() async {
    try {
      final service = SettingsService.to;
      return SettingsModel(
        status: true,
        downloadPath: service.downloadPath,
        defaultQuality: service.defaultQuality,
        defaultType: service.defaultType,
        preferYtdlp: service.preferYtdlp,
      );
    } catch (e) {
      return SettingsModel(
        status: false,
        detail: '${AppStrings.msgLoadSettingsError}: $e',
      );
    }
  }

  @override
  Future<SettingsModel> saveSettings(SettingsModel settings) async {
    try {
      final service = SettingsService.to;
      if (settings.downloadPath != null) {
        await service.setDownloadPath(settings.downloadPath!);
      }
      if (settings.defaultQuality != null) {
        await service.setDefaultQuality(settings.defaultQuality!);
      }
      if (settings.defaultType != null) {
        await service.setDefaultType(settings.defaultType!);
      }
      if (settings.preferYtdlp != null) {
        await service.setPreferYtdlp(settings.preferYtdlp!);
      }
      return SettingsModel(status: true, detail: 'Configuracoes salvas com sucesso!');
    } catch (e) {
      return SettingsModel(
        status: false,
        detail: '${AppStrings.msgSaveSettingsError}: $e',
      );
    }
  }
}
