import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/repositories/playlist_repository.dart';
import '../../providers/media_scan_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../video/player/video_player_screen.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<PlaylistModel> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final data = await PlaylistRepository.getPlaylists();
    setState(() {
      _playlists = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("কাস্টম প্লেলিস্ট (Playlists)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _playlists.isEmpty
              ? const Center(
                  child: Text("কোনো প্লেলিস্ট তৈরি করা হয়নি", style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _playlists.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final pl = _playlists[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.playlist_play_rounded, color: AppColors.primary, size: 30),
                      ),
                      title: Text(pl.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${pl.itemCount} টি ফাইল", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                        onPressed: () async {
                          await PlaylistRepository.deletePlaylist(pl.id);
                          _loadPlaylists();
                        },
                      ),
                      onTap: () => _openPlaylistDetails(context, pl),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("নতুন প্লেলিস্ট", style: TextStyle(color: Colors.white)),
        onPressed: _showCreateDialog,
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("প্লেলিস্ট তৈরি করুন"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "প্লেলিস্টের নাম (যেমন: প্রিয় গান)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await PlaylistRepository.createPlaylist(name);
                Navigator.pop(ctx);
                _loadPlaylists();
              }
            },
            child: const Text("সংরক্ষণ", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetails(BuildContext context, PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistDetailView(playlist: playlist, onRefresh: _loadPlaylists)),
    );
  }
}

class PlaylistDetailView extends ConsumerWidget {
  final PlaylistModel playlist;
  final VoidCallback onRefresh;

  const PlaylistDetailView({super.key, required this.playlist, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(playlist.name, style: const TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<String>>(
        future: PlaylistRepository.getPlaylistFilePaths(playlist.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final paths = snapshot.data!;

          if (paths.isEmpty) {
            return const Center(child: Text("প্লেলিস্টে কোনো মিডিয়া ফাইল নেই", style: TextStyle(color: AppColors.textSecondary)));
          }

          final allMedia = [...mediaState.allVideos, ...mediaState.allAudios];
          final playlistItems = paths.map((p) => allMedia.firstWhere((m) => m.path == p, orElse: () => allMedia.first)).toList();

          return ListView.separated(
            itemCount: playlistItems.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final item = playlistItems[index];
              return ListTile(
                leading: Icon(item.isVideo ? Icons.movie_outlined : Icons.music_note_rounded, color: AppColors.primary),
                title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(item.formattedDuration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                  onPressed: () async {
                    await PlaylistRepository.removePlaylistItem(playlist.id, item.path);
                    onRefresh();
                  },
                ),
                onTap: () {
                  if (item.isVideo) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(media: item)));
                  } else {
                    ref.read(audioPlayerProvider.notifier).playSong(item, customPlaylist: playlistItems);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}