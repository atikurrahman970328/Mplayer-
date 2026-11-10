import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/db_helper.dart';
import '../../providers/media_scan_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../video/player/video_player_screen.dart';

class RecentHistoryPage extends ConsumerStatefulWidget {
  const RecentHistoryPage({super.key});

  @override
  ConsumerState<RecentHistoryPage> createState() => _RecentHistoryPageState();
}

class _RecentHistoryPageState extends ConsumerState<RecentHistoryPage> {
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('playback_history', orderBy: 'last_played_timestamp DESC');
    setState(() {
      _historyItems = res;
      _isLoading = false;
    });
  }

  Future<void> _clearAllHistory() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('playback_history');
    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("প্লেব্যাক হিস্ট্রি (History)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "Clear All History",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text("হিস্ট্রি মুছে ফেলবেন?"),
                    content: const Text("দেখা সব ভিডিও ও শোনার হিস্ট্রি তালিকা মুছে ফেলা হবে।"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearAllHistory();
                        },
                        child: const Text("মুছুন", style: TextStyle(color: AppColors.errorRed)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _historyItems.isEmpty
              ? const Center(
                  child: Text("কোনো প্লেব্যাক ইতিহাস সংরক্ষিত নেই", style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  itemCount: _historyItems.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final hist = _historyItems[index];
                    final filePath = hist['file_path'] as String;
                    final isVideo = hist['media_type'] == 'video';
                    final watchedPerc = hist['watched_percentage'] as double;

                    final all = isVideo ? mediaState.allVideos : mediaState.allAudios;
                    final mediaItem = all.firstWhere((m) => m.path == filePath, orElse: () => all.first);

                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                        child: Icon(isVideo ? Icons.movie_outlined : Icons.music_note_rounded, color: AppColors.primary),
                      ),
                      title: Text(mediaItem.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("দেখা হয়েছে: ${watchedPerc.toStringAsFixed(1)}%", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (watchedPerc / 100).clamp(0.0, 1.0),
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 2,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () async {
                          final db = await DatabaseHelper.instance.database;
                          await db.delete('playback_history', where: 'file_path = ?', whereArgs: [filePath]);
                          _fetchHistory();
                        },
                      ),
                      onTap: () {
                        if (isVideo) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(media: mediaItem)));
                        } else {
                          ref.read(audioPlayerProvider.notifier).playSong(mediaItem);
                        }
                      },
                    );
                  },
                ),
    );
  }
}