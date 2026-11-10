import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';

class StorageAnalyzerPage extends ConsumerStatefulWidget {
  const StorageAnalyzerPage({super.key});

  @override
  ConsumerState<StorageAnalyzerPage> createState() => _StorageAnalyzerPageState();
}

class _StorageAnalyzerPageState extends ConsumerState<StorageAnalyzerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);

    // ১. মোট সাইজ হিসাব
    final int totalVideoBytes = mediaState.allVideos.fold(0, (sum, item) => sum + item.size);
    final int totalAudioBytes = mediaState.allAudios.fold(0, (sum, item) => sum + item.size);
    final int totalCombinedBytes = totalVideoBytes + totalAudioBytes;

    // ২. বড় ফাইলসমূহ (৫০ মেগাবাইট বা তার বেশি)
    final largeFiles = [...mediaState.allVideos, ...mediaState.allAudios]
        .where((m) => m.size >= (50 * 1024 * 1024))
        .toList()
      ..sort((a, b) => b.size.compareTo(a.size));

    // ৩. ডুপ্লিকেট ফাইল সনাক্তকরণ (একই ফাইলের সাইজ ও নাম)
    final Map<int, List<MediaItem>> sizeMap = {};
    for (var m in [...mediaState.allVideos, ...mediaState.allAudios]) {
      sizeMap.putIfAbsent(m.size, () => []).add(m);
    }
    final duplicateGroups = sizeMap.values.where((list) => list.length > 1).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("স্টোরেজ অ্যানালাইজার (Storage Analyzer)", style: TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: "বড় ফাইল (${largeFiles.length})"),
            Tab(text: "ডুপ্লিকেট ফাইল (${duplicateGroups.length})"),
          ],
        ),
      ),
      body: Column(
        children: [
          // স্টোরেজ ভিজ্যুয়ালাইজেশন কার্ড
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("অফলাইন মিডিয়া দখলকৃত স্টোরেজ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(_formatBytes(totalCombinedBytes), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: totalCombinedBytes > 0 ? (totalVideoBytes * 100 ~/ totalCombinedBytes) : 50,
                          child: Container(color: AppColors.primary),
                        ),
                        Expanded(
                          flex: totalCombinedBytes > 0 ? (totalAudioBytes * 100 ~/ totalCombinedBytes) : 50,
                          child: Container(color: AppColors.activeGreen),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem("ভিডিও (${mediaState.allVideos.length})", _formatBytes(totalVideoBytes), AppColors.primary),
                    _buildLegendItem("গান/অডিও (${mediaState.allAudios.length})", _formatBytes(totalAudioBytes), AppColors.activeGreen),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLargeFilesList(largeFiles),
                _buildDuplicateGroupsList(duplicateGroups),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String size, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text("$label: ", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(size, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLargeFilesList(List<MediaItem> list) {
    if (list.isEmpty) {
      return const Center(child: Text("৫০ মেগাবাইটের বেশি বড় কোনো ফাইল নেই", style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          leading: Icon(item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded, color: AppColors.primary),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: Text("${item.folderName} • ${item.formattedDuration}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.formattedSize, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                onPressed: () => _deleteFile(item),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDuplicateGroupsList(List<List<MediaItem>> groups) {
    if (groups.isEmpty) {
      return const Center(child: Text("কোনো ডুপ্লিকেট ফাইল পাওয়া যায়নি", style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final duplicates = groups[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("অনুরূপ ফাইল গ্রুপ #${i + 1}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(duplicates.first.formattedSize, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
              ...duplicates.map(
                (file) => ListTile(
                  dense: true,
                  title: Text(file.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 18),
                    onPressed: () => _deleteFile(file),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteFile(MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ফাইল মুছে ফেলতে চান?"),
        content: Text("\"${item.displayName}\" ডিভাইস থেকে স্থায়ীভাবে ডিলিট হবে।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              try {
                final f = File(item.path);
                if (f.existsSync()) f.deleteSync();
                ref.read(mediaProvider.notifier).initAndScan();
              } catch (_) {}
            },
            child: const Text("মুছুন", style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}