import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/folder_model.dart';
import '../../providers/media_scan_provider.dart';
import 'folder_detail_page.dart';

class FolderBrowserPage extends ConsumerWidget {
  const FolderBrowserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final folders = mediaState.videoFolders;

    if (folders.isEmpty) {
      return const Center(
        child: Text("কোনো ভিডিও ফোল্ডার পাওয়া যায়নি", style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (context, index) {
          final folder = folders[index];
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.amberAccent, size: 30),
            ),
            title: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${folder.videoCount} টি ভিডিও • ${folder.formattedTotalSize}",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderDetailPage(folder: folder),
                ),
              );
            },
          );
        },
      ),
    );
  }
}