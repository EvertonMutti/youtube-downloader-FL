import 'package:flutter/material.dart';
import 'package:youtube_downloader/app/core/constants/app_colors.dart';
import 'package:youtube_downloader/app/core/constants/app_strings.dart';

class UrlInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onFetch;

  const UrlInputWidget({
    super.key,
    required this.controller,
    required this.loading,
    required this.onFetch,
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
              AppStrings.labelUrlInput,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textSecondary),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: AppStrings.labelUrlHint,
                prefixIcon: Icon(Icons.link, color: AppColors.primary),
              ),
              onSubmitted: (_) => loading ? null : onFetch(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                      )
                    : const Icon(Icons.search),
                label: Text(loading ? AppStrings.labelFetching : AppStrings.labelFetch),
                onPressed: loading ? null : onFetch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
