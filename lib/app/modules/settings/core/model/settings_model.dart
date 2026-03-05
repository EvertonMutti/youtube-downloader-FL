import 'package:youtube_downloader/app/core/enums/audio_format.dart';
import 'package:youtube_downloader/app/core/enums/download_type.dart';
import 'package:youtube_downloader/app/core/enums/quality_option.dart';

class SettingsModel {
  final bool? status;
  final String? detail;
  final String? downloadPath;
  final QualityOption? defaultQuality;
  final DownloadType? defaultType;
  final bool? preferYtdlp;
  final AudioFormat? audioFormat;

  SettingsModel({
    this.status,
    this.detail,
    this.downloadPath,
    this.defaultQuality,
    this.defaultType,
    this.preferYtdlp,
    this.audioFormat,
  });

  SettingsModel copyWith({
    bool? status,
    String? detail,
    String? downloadPath,
    QualityOption? defaultQuality,
    DownloadType? defaultType,
    bool? preferYtdlp,
    AudioFormat? audioFormat,
  }) {
    return SettingsModel(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      downloadPath: downloadPath ?? this.downloadPath,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultType: defaultType ?? this.defaultType,
      preferYtdlp: preferYtdlp ?? this.preferYtdlp,
      audioFormat: audioFormat ?? this.audioFormat,
    );
  }
}
