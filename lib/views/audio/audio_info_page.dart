import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';

class AudioInfoPage extends ConsumerWidget {
  final MediaItem audio;

  const AudioInfoPage({super.key, required this.audio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("অডিও ট্যাগ ও বিবরণ (Metadata)", style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: "Edit Song Info",
            onPressed: () => _showEditMetadataDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard("গানের নাম", audio.title, Icons.music_note_rounded),
          _buildInfoCard("পাথ", audio.path, Icons.folder_open_rounded),
          _buildInfoCard("ফোল্ডার", audio.folderName, Icons.snippet_folder_rounded),
          _buildInfoCard("আকার", audio.formattedSize, Icons.data_usage_rounded),
          _buildInfoCard("স্থিতিকাল (Duration)", audio.formattedDuration, Icons.timer_outlined),
          _buildInfoCard("এক্সটেনশন", audio.extension.toUpperCase(), Icons.audio_file_rounded),
          _buildInfoCard(
            "সর্বশেষ পরিবর্তন",
            DateTime.fromMillisecondsSinceEpoch(audio.dateModified).toString().split('.')[0],
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.activeGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 3),
                Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMetadataDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: audio.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ট্যাগ সম্পাদনা (Edit Metadata)"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: "গানের শিরোনাম"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty && newTitle != audio.title) {
                try {
                  final file = File(audio.path);
                  final newPath = "${audio.folderPath}/$newTitle.${audio.extension}";
                  file.renameSync(newPath);
                  ref.read(mediaProvider.notifier).initAndScan();
                  Navigator.pop(context);
                } catch (_) {}
              }
            },
            child: const Text("সংরক্ষণ", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}