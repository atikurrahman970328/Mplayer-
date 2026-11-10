import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/media_scan_provider.dart';
import '../../models/media_model.dart';
import 'widgets/continue_watching_slider.dart';
import '../video/all_videos_page.dart';
import '../video/folder_browser_page.dart';
import '../file_manager/file_manager_page.dart';
import '../search/search_page.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);

    // দেখা চালিয়ে যাওয়ার ভিডিও ফিল্টার (যার প্লেব্যাক প্রগ্রেস রয়েছে)
    final continueWatchingList = mediaState.allVideos
        .where((v) => v.lastPositionMs > 0 && v.watchedPercentage < 95.0)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(
              "MX PLAYER",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: "Search Offline Media",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Rescan Storage",
            onPressed: () => ref.read(mediaProvider.notifier).initAndScan(),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: "File Explorer",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FileManagerPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(mediaState, continueWatchingList),
          const AllVideosPage(),
          const FolderBrowserPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection_rounded),
            label: "All Videos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_special_rounded),
            label: "Folders",
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(MediaState state, List<MediaItem> continueWatchingList) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // সম্প্রতি অ্যাড হওয়া মিডিয়া (সংশোধনের তারিখ অনুযায়ী সাজানো)
    final recentList = List<MediaItem>.from(state.allVideos)
      ..sort((a, b) => b.dateModified.compareTo(a.dateModified));
    final topRecent = recentList.take(8).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(mediaProvider.notifier).initAndScan(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ১. Continue Watching সেকশন
          if (continueWatchingList.isNotEmpty)
            ContinueWatchingSlider(
              items: continueWatchingList,
              onResume: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playing "${item.title}" (ধাপ ৩ এ চালু হবে)')),
                );
              },
            ),

          // ২. কুইক অ্যাক্সেস গ্রিড
          _buildQuickAccessGrid(state),

          // ৩. সম্প্রতি যোগ করা ভিডিও
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.new_releases_rounded, color: AppColors.activeGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "সম্প্রতি যোগ করা (Recently Added)",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text("সব দেখুন", style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topRecent.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final media = topRecent[index];
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
                  media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${media.folderName} • ${media.formattedSize}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: Text(
                  media.extension.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing "${media.title}" (ধাপ ৩ এ প্লেয়ারে লোড হবে)')),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(MediaState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildQuickTile(
            title: "ভিডিও",
            count: "${state.allVideos.length}",
            icon: Icons.movie_creation_rounded,
            color: Colors.blueAccent,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          const SizedBox(width: 10),
          _buildQuickTile(
            title: "ফোল্ডার",
            count: "${state.videoFolders.length}",
            icon: Icons.folder_rounded,
            color: Colors.amberAccent,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(width: 10),
          _buildQuickTile(
            title: "ফাইল ম্যানেজার",
            count: "Storage",
            icon: Icons.sd_storage_rounded,
            color: Colors.tealAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FileManagerPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTile({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}