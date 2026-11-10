import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/media_model.dart';

class VideoInfoPage extends StatelessWidget {
  final MediaItem media;

  const VideoInfoPage({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ফাইলের বিস্তারিত তথ্য (Media Info)", style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoTile("ফাইলের নাম", media.displayName, Icons.title_rounded),
          _buildInfoTile("লোকেশন", media.path, Icons.folder_open_rounded),
          _buildInfoTile("আকার", media.formattedSize, Icons.data_usage_rounded),
          _buildInfoTile("স্থিতিকাল (Duration)", media.formattedDuration, Icons.timer_outlined),
          _buildInfoTile("ফরম্যাট", media.extension.toUpperCase(), Icons.extension_rounded),
          _buildInfoTile("ফোল্ডার", media.folderName, Icons.snippet_folder_rounded),
          _buildInfoTile(
            "সর্বশেষ প্লে পজিশন",
            "${(media.lastPositionMs / 1000).round()} সেকেন্ড (${media.watchedPercentage.toStringAsFixed(1)}%)",
            Icons.history_rounded,
          ),
          _buildInfoTile(
            "সংশোধনের সময়",
            DateTime.fromMillisecondsSinceEpoch(media.dateModified).toString().split('.')[0],
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}