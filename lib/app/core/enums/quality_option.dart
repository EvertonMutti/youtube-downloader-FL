import 'package:youtube_downloader/app/core/constants/app_strings.dart';

enum QualityOption {
  best('best', AppStrings.labelBestAvailable),
  p1080('1080p', '1080p'),
  p720('720p', '720p'),
  p480('480p', '480p'),
  p360('360p', '360p'),
  p240('240p', '240p'),
  p144('144p', '144p');

  const QualityOption(this.value, this.label);

  final String value;
  final String label;

  static QualityOption fromValue(String value) => QualityOption.values.firstWhere(
        (e) => e.value == value,
        orElse: () => QualityOption.best,
      );
}
