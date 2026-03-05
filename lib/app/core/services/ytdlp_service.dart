import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class YtdlpService extends GetxService {
  static YtdlpService get to => Get.find();

  static const _platformUrls = {
    'android': 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64',
    'windows': 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe',
    'macos': 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos',
    'linux': 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp',
  };

  static String get _platformKey {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'linux';
  }

  static String get _downloadUrl => _platformUrls[_platformKey]!;

  static String get _binaryName => Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';

  static bool get isSupportedPlatform =>
      Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  String? _binaryPath;

  bool get isAvailable => _binaryPath != null;

  String get binaryPath {
    assert(_binaryPath != null, 'YtdlpService: binary not available');
    return _binaryPath!;
  }

  Future<String> _resolveBinaryPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$_binaryName';
  }

  Future<void> _makeExecutable(String path) async {
    if (Platform.isWindows) return;
    final result = await Process.run('chmod', ['755', path]);
    debugPrint('[YtdlpService] chmod exitCode=${result.exitCode}');
  }

  Future<bool> _downloadAndInstall(String path) async {
    debugPrint('[YtdlpService] _downloadAndInstall: $_downloadUrl');
    final response = await http.get(Uri.parse(_downloadUrl));
    debugPrint('[YtdlpService] resposta HTTP ${response.statusCode} (${response.bodyBytes.length} bytes)');
    if (response.statusCode != 200) return false;

    await File(path).writeAsBytes(response.bodyBytes);
    await _makeExecutable(path);
    return true;
  }

  Future<YtdlpService> init() async {
    if (!isSupportedPlatform) {
      debugPrint('[YtdlpService] init: plataforma nao suportada');
      return this;
    }
    final path = await _resolveBinaryPath();
    if (!await File(path).exists()) {
      debugPrint('[YtdlpService] init: binario NAO encontrado em $path');
      return this;
    }
    await _makeExecutable(path);
    _binaryPath = path;
    debugPrint('[YtdlpService] init: binario encontrado em $path');
    return this;
  }

  Future<bool> ensureBinary() async {
    if (_binaryPath != null) {
      debugPrint('[YtdlpService] ensureBinary: binario ja disponivel em $_binaryPath');
      return true;
    }
    if (!isSupportedPlatform) {
      debugPrint('[YtdlpService] ensureBinary: plataforma nao suportada');
      return false;
    }

    try {
      final path = await _resolveBinaryPath();
      final success = await _downloadAndInstall(path);
      if (!success) return false;
      _binaryPath = path;
      debugPrint('[YtdlpService] ensureBinary: binario pronto em $path');
      return true;
    } catch (e) {
      debugPrint('[YtdlpService] ensureBinary: ERRO — $e');
      return false;
    }
  }

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

  Future<void> removeBinary() async {
    if (_binaryPath == null) return;
    debugPrint('[YtdlpService] removeBinary: removendo $_binaryPath');
    final file = File(_binaryPath!);
    if (await file.exists()) await file.delete();
    _binaryPath = null;
    debugPrint('[YtdlpService] removeBinary: binario removido');
  }
}
