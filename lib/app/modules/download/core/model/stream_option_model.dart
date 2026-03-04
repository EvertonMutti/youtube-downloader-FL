class StreamOptionModel {
  final bool? status;
  final String? detail;
  final String label;
  final String tag;
  final bool isAudioOnly;
  final int? bitrate;
  final String? container;

  StreamOptionModel({
    this.status,
    this.detail,
    required this.label,
    required this.tag,
    required this.isAudioOnly,
    this.bitrate,
    this.container,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StreamOptionModel && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;
}
