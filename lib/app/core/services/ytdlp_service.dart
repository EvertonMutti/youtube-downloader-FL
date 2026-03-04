import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class YtdlpService extends GetxService {
  static YtdlpService get to => Get.find();

  static String get _binaryName => Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';

  static String get _downloadUrl {
    if (Platform.isAndroid) {
      return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64';
    }
    if (Platform.isWindows) {
      return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
    }
    if (Platform.isMacOS) {
      return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos';
    }
    return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp';
  }

  static bool get isSupportedPlatform =>
      Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  String? _binaryPath;

  bool get isAvailable => _binaryPath != null;

  String get binaryPath {
    assert(_binaryPath != null, 'YtdlpService: binary not available');
    return _binaryPath!;
  }

  Future<YtdlpService> init() async {
    if (!isSupportedPlatform) {
      debugPrint('[YtdlpService] init: plataforma nao suportada');
      return this;
    }
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/$_binaryName';
    final file = File(path);
    if (await file.exists()) {
      _binaryPath = path;
      debugPrint('[YtdlpService] init: binario encontrado em $path');
    } else {
      debugPrint('[YtdlpService] init: binario NAO encontrado em $path');
    }
    return this;
  }

  /// Downloads the yt-dlp binary if not already present and marks it executable.
  /// Returns true on success, false on failure.
  Future<bool> ensureBinary() async {
    if (_binaryPath != null) {
      debugPrint('[YtdlpService] ensureBinary: binario ja disponivel em $_binaryPath');
      return true;
    }
    if (!isSupportedPlatform) {
      debugPrint('[YtdlpService] ensureBinary: plataforma nao suportada');
      return false;
    }

    debugPrint('[YtdlpService] ensureBinary: iniciando download de $_downloadUrl');
    try {
      final dir = await getApplicationSupportDirectory();
      final path = '${dir.path}/$_binaryName';
      final file = File(path);

      final response = await http.get(Uri.parse(_downloadUrl));
      debugPrint('[YtdlpService] ensureBinary: resposta HTTP ${response.statusCode} (${response.bodyBytes.length} bytes)');
      if (response.statusCode != 200) return false;

      await file.writeAsBytes(response.bodyBytes);

      if (!Platform.isWindows) {
        final chmodResult = await Process.run('chmod', ['755', path]);
        debugPrint('[YtdlpService] ensureBinary: chmod exitCode=${chmodResult.exitCode}');
        if (chmodResult.exitCode != 0) return false;
      }

      _binaryPath = path;
      debugPrint('[YtdlpService] ensureBinary: binario pronto em $path');
      return true;
    } catch (e) {
      debugPrint('[YtdlpService] ensureBinary: ERRO — $e');
      return false;
    }
  }

  /// Updates the yt-dlp binary using its built-in self-update mechanism.
  /// Falls back to re-download if the binary is not available.
  /// Returns true on success, false on failure.
  Future<bool> updateBinary() async {
    if (_binaryPath == null) {
      debugPrint('[YtdlpService] updateBinary: binario nao disponivel, redirecionando para ensureBinary');
      return ensureBinary();
    }
    debugPrint('[YtdlpService] updateBinary: executando yt-dlp -U');
    try {
      final result = await Process.run(_binaryPath!, ['-U']);
      debugPrint('[YtdlpService] updateBinary: exitCode=${result.exitCode}');
      if (result.stdout.toString().isNotEmpty) {
        debugPrint('[YtdlpService] updateBinary: stdout=${result.stdout}');
      }
      if (result.exitCode != 0) {
        debugPrint('[YtdlpService] updateBinary: stderr=${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[YtdlpService] updateBinary: ERRO — $e');
      return false;
    }
  }

  /// Removes the downloaded binary and resets availability.
  Future<void> removeBinary() async {
    if (_binaryPath == null) return;
    debugPrint('[YtdlpService] removeBinary: removendo $_binaryPath');
    final file = File(_binaryPath!);
    if (await file.exists()) await file.delete();
    _binaryPath = null;
    debugPrint('[YtdlpService] removeBinary: binario removido');
  }
}
