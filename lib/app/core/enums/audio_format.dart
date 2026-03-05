enum AudioFormat {
  mp3('mp3', 'MP3'),
  m4a('m4a', 'M4A');

  const AudioFormat(this.value, this.label);
  final String value;
  final String label;

  static AudioFormat fromValue(String value) => AudioFormat.values.firstWhere(
        (e) => e.value == value,
        orElse: () => AudioFormat.mp3,
      );
}
