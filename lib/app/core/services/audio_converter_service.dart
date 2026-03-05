import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:youtube_downloader/app/core/enums/audio_format.dart';

class AudioConverterService {
  AudioConverterService._();

  static Future<String> convert(String inputPath, AudioFormat format) async {
    final outputPath = _replaceExtension(inputPath, format.value);
    debugPrint('[AudioConverter] convert: $inputPath → $outputPath (${format.label})');

    final success = await _runFfmpeg(inputPath, outputPath, format);
    if (!success) return inputPath;

    await _deleteOriginal(inputPath);
    return outputPath;
  }

  static Future<String> convertToMp3(String inputPath) => convert(inputPath, AudioFormat.mp3);

  static List<String> _buildFfmpegArgs(String input, String output, AudioFormat format) {
    final codecArgs = format == AudioFormat.m4a
        ? ['-codec:a', 'aac', '-q:a', '1']
        : ['-codec:a', 'libmp3lame', '-q:a', '2'];
    return ['-i', input, ...codecArgs, output, '-y'];
  }

  static Future<bool> _runFfmpeg(String input, String output, AudioFormat format) async {
    try {
      final result = await Process.run('ffmpeg', _buildFfmpegArgs(input, output, format));
      if (result.exitCode == 0 && await File(output).exists()) {
        debugPrint('[AudioConverter] conversao concluida: $output');
        return true;
      }
      debugPrint('[AudioConverter] conversao falhou (exitCode=${result.exitCode}) — mantendo original');
      return false;
    } catch (e) {
      debugPrint('[AudioConverter] ffmpeg indisponivel ou erro — mantendo original: $e');
      return false;
    }
  }

  static Future<void> _deleteOriginal(String path) async {
    try {
      await File(path).delete();
    } catch (e) {
      debugPrint('[AudioConverter] aviso: nao foi possivel remover arquivo original — $e');
    }
  }

  static String _replaceExtension(String filePath, String newExt) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '$filePath.$newExt';
    return '${filePath.substring(0, lastDot)}.$newExt';
  }
}
