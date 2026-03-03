import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/core/enums/download_type.dart';
import 'package:youtube_downloader/app/core/enums/quality_option.dart';
import 'package:youtube_downloader/app/modules/settings/controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.labelSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.getLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(AppStrings.labelDownloadFolder),
              const SizedBox(height: 8),
              _buildPathSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle(AppStrings.labelDefaultType),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle(AppStrings.labelDefaultQuality),
              const SizedBox(height: 8),
              _buildQualitySelector(),
              if (controller.isAndroid) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(AppStrings.labelYtdlpSection),
                const SizedBox(height: 8),
                _buildYtdlpSelector(),
              ],
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPathSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.pathController,
              readOnly: true,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: AppStrings.labelNoFolderSelected,
                prefixIcon: Icon(Icons.folder, color: AppColors.amber),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text(AppStrings.labelChangeFolder),
                onPressed: controller.pickDirectory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Obx(() => RadioListTile<DownloadType>(
                  title: const Text(AppStrings.labelVideo,
                      style: TextStyle(color: AppColors.textSecondary)),
                  value: DownloadType.video,
                  groupValue: controller.getSelectedType,
                  activeColor: AppColors.primary,
                  onChanged: controller.onTypeChanged,
                )),
            Obx(() => RadioListTile<DownloadType>(
                  title: const Text(AppStrings.labelAudioOnly,
                      style: TextStyle(color: AppColors.textSecondary)),
                  value: DownloadType.audio,
                  groupValue: controller.getSelectedType,
                  activeColor: AppColors.primary,
                  onChanged: controller.onTypeChanged,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(() => DropdownButtonFormField<QualityOption>(
              value: controller.getSelectedQuality,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textSecondary),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.hd, color: AppColors.accent),
              ),
              items: controller.qualityOptions.map((q) {
                return DropdownMenuItem(
                  value: q,
                  child: Text(q.label),
                );
              }).toList(),
              onChanged: controller.onQualityChanged,
            )),
      ),
    );
  }

  Widget _buildYtdlpSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => SwitchListTile(
                  title: const Text(
                    AppStrings.labelPreferYtdlp,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  subtitle: const Text(
                    AppStrings.labelPreferYtdlpSubtitle,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: controller.getPreferYtdlp,
                  activeThumbColor: AppColors.primary,
                  onChanged: controller.onPreferYtdlpChanged,
                )),
            const SizedBox(height: 4),
            Obx(() {
              if (controller.isYtdlpInstalled) {
                return const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Text(
                        AppStrings.labelYtdlpReady,
                        style: TextStyle(color: AppColors.success, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: controller.getDownloadingYtdlp
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.msgYtdlpDownloading,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text(AppStrings.labelDownloadYtdlp),
                        onPressed: controller.downloadYtdlpBinary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => ElevatedButton.icon(
          icon: controller.getSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                )
              : const Icon(Icons.save),
          label: Text(controller.getSaving ? AppStrings.labelSaving : AppStrings.labelSave),
          onPressed: controller.getSaving ? null : controller.saveSettings,
        ));
  }
}
