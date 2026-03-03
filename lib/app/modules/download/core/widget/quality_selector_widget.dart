import 'package:flutter/material.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';
import 'package:youtube_downloader/app/modules/download/core/model/stream_option_model.dart';

class QualitySelectorWidget extends StatelessWidget {
  final bool audioOnly;
  final List<StreamOptionModel> options;
  final StreamOptionModel? selectedOption;
  final void Function(bool audioOnly) onTypeChanged;
  final void Function(StreamOptionModel?) onQualityChanged;

  const QualitySelectorWidget({
    super.key,
    required this.audioOnly,
    required this.options,
    required this.selectedOption,
    required this.onTypeChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.labelTypeAndQuality,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildTypeToggle(),
            const SizedBox(height: 14),
            if (options.isNotEmpty) _buildQualityDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !audioOnly ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam,
                      size: 16,
                      color: !audioOnly ? AppColors.textPrimary : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.labelVideo,
                    style: TextStyle(
                      color: !audioOnly ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onTypeChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: audioOnly ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audiotrack,
                      size: 16,
                      color: audioOnly ? AppColors.textPrimary : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.labelAudio,
                    style: TextStyle(
                      color: audioOnly ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityDropdown() {
    final validOptions = options.where((o) => o.status == true && o.tag.isNotEmpty).toList();

    if (validOptions.isEmpty) {
      return Text(
        options.first.detail ?? AppStrings.labelNoQualityAvailable,
        style: const TextStyle(color: AppColors.warning, fontSize: 13),
      );
    }

    return DropdownButtonFormField<StreamOptionModel>(
      initialValue: selectedOption != null && validOptions.contains(selectedOption)
          ? selectedOption
          : validOptions.first,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textSecondary),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.tune, color: AppColors.accent),
      ),
      items: validOptions.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: onQualityChanged,
    );
  }
}
