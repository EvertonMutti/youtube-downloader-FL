enum DownloadType {
  video('video'),
  audio('audio');

  const DownloadType(this.value);

  final String value;

  static DownloadType fromValue(String value) => DownloadType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => DownloadType.video,
      );
}
