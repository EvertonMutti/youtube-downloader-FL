import 'package:flutter/material.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/modules/download/core/model/download_task_model.dart';

class DownloadProgressWidget extends StatelessWidget {
  final DownloadTaskModel task;

  const DownloadProgressWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: task.downloadStatus == DownloadStatus.downloading
                    ? task.progress
                    : task.downloadStatus == DownloadStatus.completed
                        ? 1.0
                        : null,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            task.title ?? AppStrings.labelDownloading,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    switch (task.downloadStatus) {
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: AppColors.success, size: 22);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel_outlined, color: AppColors.textMuted, size: 22);
      case DownloadStatus.error:
        return const Icon(Icons.error, color: AppColors.primary, size: 22);
      case DownloadStatus.fetching:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.info),
        );
      default:
        return const Icon(Icons.download, color: AppColors.textMuted, size: 22);
    }
  }

  Widget _buildStatusText() {
    final String statusText;
    final Color statusColor;

    switch (task.downloadStatus) {
      case DownloadStatus.downloading:
        final percent = (task.progress * 100).toStringAsFixed(0);
        if (task.totalItems > 1) {
          statusText = '${task.currentItem}/${task.totalItems} - $percent%';
        } else {
          statusText = '$percent${AppStrings.statusPercent}';
        }
        statusColor = AppColors.textSecondary;
      case DownloadStatus.completed:
        statusText = AppStrings.statusCompleted;
        statusColor = AppColors.success;
      case DownloadStatus.cancelled:
        statusText = AppStrings.statusCancelled;
        statusColor = AppColors.textMuted;
      case DownloadStatus.error:
        statusText = task.detail ?? AppStrings.statusError;
        statusColor = Colors.redAccent;
      case DownloadStatus.fetching:
        statusText = AppStrings.statusFetching;
        statusColor = AppColors.info;
      default:
        statusText = AppStrings.statusWaiting;
        statusColor = AppColors.textMuted;
    }

    return Text(
      statusText,
      style: TextStyle(color: statusColor, fontSize: 13),
    );
  }
}
