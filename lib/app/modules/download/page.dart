import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/core/routes/app_routes.dart';
import 'package:youtube_downloader/app/modules/download/controller.dart';
import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';
import 'package:youtube_downloader/app/modules/download/core/widget/download_progress_widget.dart';
import 'package:youtube_downloader/app/modules/download/core/widget/quality_selector_widget.dart';
import 'package:youtube_downloader/app/modules/download/core/widget/url_input_widget.dart';
import 'package:youtube_downloader/app/modules/download/core/widget/video_info_card.dart';

class DownloadPage extends GetView<DownloadController> {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.textPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.tooltipSettings,
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrlInput(),
            const SizedBox(height: 16),
            _buildVideoInfo(),
            _buildQualitySelector(),
            _buildDownloadButton(),
            _buildProgressSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Obx(() => UrlInputWidget(
          controller: controller.urlController,
          loading: controller.getFetching,
          onFetch: controller.fetchInfo,
        ));
  }

  Widget _buildVideoInfo() {
    return Obx(() {
      final info = controller.getVideoInfo;
      if (info == null) return const SizedBox.shrink();
      return Column(
        children: [
          VideoInfoCard(info: info),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildQualitySelector() {
    return Obx(() {
      final info = controller.getVideoInfo;
      if (info == null) return const SizedBox.shrink();

      // Playlist uses auto quality - show simplified type selector
      if (info.isPlaylist) {
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.labelDownloadType,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => RadioListTile<bool>(
                                title: const Text(
                                  AppStrings.labelVideo,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                value: false,
                                groupValue: controller.getAudioOnly,
                                activeColor: AppColors.primary,
                                onChanged: (v) => controller.onTypeChanged(v ?? false),
                              )),
                        ),
                        Expanded(
                          child: Obx(() => RadioListTile<bool>(
                                title: const Text(
                                  AppStrings.labelAudio,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                value: true,
                                groupValue: controller.getAudioOnly,
                                activeColor: AppColors.primary,
                                onChanged: (v) => controller.onTypeChanged(v ?? false),
                              )),
                        ),
                      ],
                    ),
                    const Text(
                      AppStrings.labelPlaylistQualityNote,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }

      if (controller.getLoadingOptions) {
        return const Column(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
            SizedBox(height: 16),
          ],
        );
      }

      return Column(
        children: [
          QualitySelectorWidget(
            audioOnly: controller.getAudioOnly,
            options: controller.getStreamOptions,
            selectedOption: controller.getSelectedOption,
            onTypeChanged: controller.onTypeChanged,
            onQualityChanged: controller.onQualityChanged,
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildDownloadButton() {
    return Obx(() {
      final info = controller.getVideoInfo;
      if (info == null) return const SizedBox.shrink();

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: controller.getDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    controller.getDownloading
                        ? AppStrings.labelDownloading
                        : info.isPlaylist
                            ? '${AppStrings.labelDownloadPlaylist} (${info.playlistCount ?? 0} ${AppStrings.labelVideos})'
                            : AppStrings.labelDownload,
                  ),
                  onPressed: controller.getDownloading ? null : controller.startDownload,
                ),
              ),
              if (controller.getDownloading) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(AppStrings.labelCancel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.textMuted),
                  ),
                  onPressed: controller.cancelDownload,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildProgressSection() {
    return Obx(() {
      final task = controller.getCurrentTask;
      if (task == null || task.downloadStatus == DownloadStatus.idle) {
        return const SizedBox.shrink();
      }
      return DownloadProgressWidget(task: task);
    });
  }
}
