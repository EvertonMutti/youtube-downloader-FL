import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class YtdlpService extends GetxService {
  static YtdlpService get to => Get.find();

  static const _binaryName = 'yt-dlp';
  static const _downloadUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64';

  String? _binaryPath;

  bool get isAvailable => _binaryPath != null;

  String get binaryPath {
    assert(_binaryPath != null, 'YtdlpService: binary not available');
    return _binaryPath!;
  }

  Future<YtdlpService> init() async {
    if (!Platform.isAndroid) return this;
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/$_binaryName';
    final file = File(path);
    if (await file.exists()) {
      _binaryPath = path;
    }
    return this;
  }

  /// Downloads the yt-dlp binary if not already present and marks it executable.
  /// Returns true on success, false on failure.
  Future<bool> ensureBinary() async {
    if (_binaryPath != null) return true;
    if (!Platform.isAndroid) return false;

    try {
      final dir = await getApplicationSupportDirectory();
      final path = '${dir.path}/$_binaryName';
      final file = File(path);

      final response = await http.get(Uri.parse(_downloadUrl));
      if (response.statusCode != 200) return false;

      await file.writeAsBytes(response.bodyBytes);

      final chmodResult = await Process.run('chmod', ['755', path]);
      if (chmodResult.exitCode != 0) return false;

      _binaryPath = path;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes the downloaded binary and resets availability.
  Future<void> removeBinary() async {
    if (_binaryPath == null) return;
    final file = File(_binaryPath!);
    if (await file.exists()) await file.delete();
    _binaryPath = null;
  }
}
