import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/app/core/enums/audio_format.dart';
import 'package:youtube_downloader/app/core/enums/download_type.dart';
import 'package:youtube_downloader/app/core/enums/quality_option.dart';
import 'package:youtube_downloader/app/core/utils/file_utils.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find();

  static const _keyDownloadPath = 'download_path';
  static const _keyDefaultQuality = 'default_quality';
  static const _keyDefaultType = 'default_type';
  static const _keyPreferYtdlp = 'prefer_ytdlp';
  static const _keyAudioFormat = 'audio_format';

  late SharedPreferences _prefs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  String get downloadPath =>
      _prefs.getString(_keyDownloadPath) ?? FileUtils.getDefaultDownloadPath();

  T _getEnum<T>(String key, String defaultValue, T Function(String) fromValue) =>
      fromValue(_prefs.getString(key) ?? defaultValue);

  QualityOption get defaultQuality =>
      _getEnum(_keyDefaultQuality, QualityOption.best.value, QualityOption.fromValue);

  DownloadType get defaultType =>
      _getEnum(_keyDefaultType, DownloadType.video.value, DownloadType.fromValue);

  Future<void> setDownloadPath(String path) async {
    await _prefs.setString(_keyDownloadPath, path);
  }

  Future<void> setDefaultQuality(QualityOption quality) async {
    await _prefs.setString(_keyDefaultQuality, quality.value);
  }

  Future<void> setDefaultType(DownloadType type) async {
    await _prefs.setString(_keyDefaultType, type.value);
  }

  bool get preferYtdlp => _prefs.getBool(_keyPreferYtdlp) ?? false;

  Future<void> setPreferYtdlp(bool value) async {
    await _prefs.setBool(_keyPreferYtdlp, value);
  }

  AudioFormat get audioFormat =>
      _getEnum(_keyAudioFormat, AudioFormat.mp3.value, AudioFormat.fromValue);

  Future<void> setAudioFormat(AudioFormat format) async {
    await _prefs.setString(_keyAudioFormat, format.value);
  }
}
