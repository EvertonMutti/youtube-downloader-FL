import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/core/enums/download_type.dart';
import 'package:youtube_downloader/app/core/enums/quality_option.dart';
import 'package:youtube_downloader/app/core/services/ytdlp_service.dart';
import 'package:youtube_downloader/app/modules/settings/core/model/settings_model.dart';
import 'package:youtube_downloader/app/modules/settings/repository.dart';

class SettingsController extends GetxController {
  final SettingsRepository repository;

  SettingsController({required this.repository});

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxBool downloadingYtdlp = false.obs;

  final TextEditingController pathController = TextEditingController();
  final Rx<QualityOption> selectedQuality = QualityOption.best.obs;
  final Rx<DownloadType> selectedType = DownloadType.video.obs;
  final RxBool preferYtdlp = false.obs;

  final List<QualityOption> qualityOptions = QualityOption.values;

  bool get getLoading => loading.value;
  bool get getSaving => saving.value;
  bool get getDownloadingYtdlp => downloadingYtdlp.value;
  QualityOption get getSelectedQuality => selectedQuality.value;
  DownloadType get getSelectedType => selectedType.value;
  bool get getPreferYtdlp => preferYtdlp.value;
  bool get isAndroid => Platform.isAndroid;
  bool get isYtdlpInstalled => Platform.isAndroid && YtdlpService.to.isAvailable;

  set setLoading(bool value) => loading.value = value;
  set setSaving(bool value) => saving.value = value;

  @override
  Future<void> onReady() async {
    super.onReady();
    await loadSettings();
  }

  @override
  void onClose() {
    pathController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    setLoading = true;
    final result = await repository.loadSettings();
    setLoading = false;

    if (result.status == true) {
      pathController.text = result.downloadPath ?? '';
      selectedQuality.value = result.defaultQuality ?? QualityOption.best;
      selectedType.value = result.defaultType ?? DownloadType.video;
      preferYtdlp.value = result.preferYtdlp ?? false;
    } else {
      Get.snackbar(
        AppStrings.snackError,
        result.detail ?? AppStrings.msgLoadSettingsError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppStrings.labelSelectFolderDialog,
    );
    if (path != null) {
      pathController.text = path;
    }
  }

  void onQualityChanged(QualityOption? quality) {
    if (quality != null) {
      selectedQuality.value = quality;
    }
  }

  void onTypeChanged(DownloadType? type) {
    if (type != null) {
      selectedType.value = type;
    }
  }

  void onPreferYtdlpChanged(bool? value) {
    if (value != null) preferYtdlp.value = value;
  }

  Future<void> downloadYtdlpBinary() async {
    downloadingYtdlp.value = true;
    final success = await YtdlpService.to.ensureBinary();
    downloadingYtdlp.value = false;

    if (success) {
      Get.snackbar(
        AppStrings.snackSuccess,
        AppStrings.msgYtdlpSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
      );
    } else {
      Get.snackbar(
        AppStrings.snackError,
        AppStrings.msgYtdlpError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> saveSettings() async {
    if (pathController.text.trim().isEmpty) {
      Get.snackbar(
        AppStrings.snackWarning,
        AppStrings.msgNoDownloadFolder,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: AppColors.textPrimary,
      );
      return;
    }

    setSaving = true;
    final result = await repository.saveSettings(
      SettingsModel(
        downloadPath: pathController.text.trim(),
        defaultQuality: selectedQuality.value,
        defaultType: selectedType.value,
        preferYtdlp: preferYtdlp.value,
      ),
    );
    setSaving = false;

    if (result.status == true) {
      Get.snackbar(
        AppStrings.snackSuccess,
        result.detail ?? 'Configuracoes salvas!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textPrimary,
      );
    } else {
      Get.snackbar(
        AppStrings.snackError,
        result.detail ?? AppStrings.msgSaveSettingsError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}
