import 'package:youtube_downloader/app/modules/settings/core/model/settings_model.dart';

abstract class SettingsRepository {
  Future<SettingsModel> loadSettings();
  Future<SettingsModel> saveSettings(SettingsModel settings);
}
