import 'dart:io';

import 'package:flutter/foundation.dart';

class AudioConverterService {
  AudioConverterService._();

  static Future<String> convertToMp3(String inputPath) async {
    final outputPath = _replaceExtension(inputPath, 'mp3');
    debugPrint('[AudioConverter] convertToMp3: $inputPath → $outputPath');

    final success = await _runFfmpeg(inputPath, outputPath);
    if (!success) return inputPath;

    await _deleteOriginal(inputPath);
    return outputPath;
  }

  static List<String> _buildFfmpegArgs(String input, String output) => [
        '-i', input,
        '-codec:a', 'libmp3lame',
        '-q:a', '2',
        output,
        '-y',
      ];

  static Future<bool> _runFfmpeg(String input, String output) async {
    try {
      final result = await Process.run('ffmpeg', _buildFfmpegArgs(input, output));
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
