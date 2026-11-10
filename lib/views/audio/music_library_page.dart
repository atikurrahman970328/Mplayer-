import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';
import '../../providers/audio_player_provider.dart';
import 'audio_info_page.dart';

class MusicLibraryPage extends ConsumerStatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  ConsumerState<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends ConsumerState<MusicLibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final audioList = mediaState.allAudios;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("মিউজিক লাইব্রেরি (Music)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: "সকল গান"),
            Tab(text: "ফোল্ডার"),
            Tab(text: "অ্যালবাম ও শিল্পী"),
          ],
        ),
      ),
      body: audioList.isEmpty
          ? const Center(
              child: Text("কোনো অডিও বা গান পাওয়া যায়নি", style: TextStyle(color: AppColors.textSecondary)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllSongsTab(audioList),
                _buildFoldersTab(mediaState.audioFolders),
                _buildArtistsTab(audioList),
              ],
            ),
    );
  }

  Widget _buildAllSongsTab(List<MediaItem> songs) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note_rounded, color: AppColors.activeGreen, size: 26),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            "${song.folderName} • ${song.formattedSize}",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (val) {
              if (val == 'info') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AudioInfoPage(audio: song)));
              } else if (val == 'fav') {
                ref.read(mediaProvider.notifier).toggleFavorite(song);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'fav', child: Text(song.isFavorite ? "পছন্দ থেকে সরান" : "পছন্দে যোগ করুন")),
              const PopupMenuItem(value: 'info', child: Text("অডিও তথ্য (Info)")),
            ],
          ),
          onTap: () {
            ref.read(audioPlayerProvider.notifier).playSong(song, customPlaylist: songs);
          },
        );
      },
    );
  }

  Widget _buildFoldersTab(List folders) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: folders.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.folder_music_rounded, color: Colors.amberAccent, size: 26),
          ),
          title: Text(folder.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("${folder.audioCount} টি গান", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildArtistsTab(List<MediaItem> songs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("স্টোরেজ ভিত্তিক আর্টিস্ট ফিল্টারিং", style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...songs.take(15).map(
              (s) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceLight,
                  child: Icon(Icons.person_rounded, color: AppColors.accent),
                ),
                title: Text(s.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(s.extension.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                onTap: () => ref.read(audioPlayerProvider.notifier).playSong(s, customPlaylist: songs),
              ),
            ),
      ],
    );
  }
}