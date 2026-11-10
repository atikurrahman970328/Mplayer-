import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/folder_model.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';

class FolderDetailPage extends ConsumerWidget {
  final MediaFolder folder;
  const FolderDetailPage({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    // এই ফোল্ডারের অধীনে থাকা ভিডিওগুলো ফিল্টার করা
    final folderVideos = mediaState.allVideos.where((v) => v.folderPath == folder.path).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              "${folderVideos.length} টি ভিডিও",
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: folderVideos.isEmpty
          ? const Center(
              child: Text("এই ফোল্ডারে কোনো ভিডিও নেই", style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              itemCount: folderVideos.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final item = folderVideos[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${item.formattedDuration} • ${item.formattedSize}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Text(
                    item.extension.toUpperCase(),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing "${item.title}" (ধাপ ৩ এ চালু হবে)')),
                    );
                  },
                );
              },
            ),
    );
  }
}