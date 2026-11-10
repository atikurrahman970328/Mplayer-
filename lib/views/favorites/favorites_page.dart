import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/media_scan_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../video/player/video_player_screen.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> with SingleTickerProviderStateMixin {
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
    final favVideos = mediaState.allVideos.where((v) => v.isFavorite).toList();
    final favAudios = mediaState.allAudios.where((a) => a.isFavorite).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("পছন্দের তালিকা (Favorites)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: "ভিডিও (${favVideos.length})"),
            Tab(text: "গান (${favAudios.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(favVideos, true),
          _buildList(favAudios, false),
        ],
      ),
    );
  }

  Widget _buildList(List items, bool isVideo) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 60, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text("কোনো পছন্দের মিডিয়া যোগ করা হয়নি", style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(isVideo ? Icons.movie_outlined : Icons.music_note_rounded, color: AppColors.primary),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
          subtitle: Text("${item.formattedDuration} • ${item.formattedSize}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.errorRed),
            onPressed: () => ref.read(mediaProvider.notifier).toggleFavorite(item),
          ),
          onTap: () {
            if (isVideo) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(media: item)));
            } else {
              ref.read(audioPlayerProvider.notifier).playSong(item);
            }
          },
        );
      },
    );
  }
}