import 'dart:io';
import 'dart:math';

class FileUtils {
  FileUtils._();

  static String sanitizeFilename(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.substring(0, min(sanitized.length, 200));
  }

  static String getDefaultDownloadPath() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/YouTubeDownloader';
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      return '$userProfile/Downloads/YouTubeDownloader';
    }
    return '';
  }

  static Future<Directory> ensureDirectoryExists(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String buildFilePath(String directory, String filename, String extension) {
    final safe = sanitizeFilename(filename);
    return '$directory/$safe.$extension';
  }
}
