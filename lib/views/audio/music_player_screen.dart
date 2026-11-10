import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/audio_player_provider.dart';
import 'audio_info_page.dart';

class MusicPlayerScreen extends ConsumerWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final song = audioState.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text("কোনো অডিও ট্র্যাক সক্রিয় নেই")),
      );
    }

    final formatDuration = (Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return d.inHours > 0 ? "${d.inHours}:$m:$s" : "$m:$s";
    };

    final maxMs = audioState.duration.inMilliseconds.toDouble();
    final curMs = audioState.position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("এখন বাজছে (Now Playing)", style: TextStyle(fontSize: 14)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AudioInfoPage(audio: song)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => _showQueueModal(context, audioState, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const Spacer(),
            // অ্যালবাম আর্টওয়ার্ক বা ভিনাইল কার্ড
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.music_note_rounded, size: 100, color: AppColors.primary),
              ),
            ),
            const Spacer(),
            // গান ও শিল্পীর নাম
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              song.folderName,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // সিকবার ও সময়
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                thumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceLight,
              ),
              child: Slider(
                value: curMs,
                max: maxMs > 0 ? maxMs : 1.0,
                onChanged: (val) {
                  ref.read(audioPlayerProvider.notifier).seek(Duration(milliseconds: val.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(audioState.position), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text(formatDuration(audioState.duration), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // মূল মিউজিক কন্ট্রোল বাটন
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // শাফল বাটন
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: audioState.isShuffle ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).toggleShuffle(),
                ),
                // পূর্ববর্তী গান
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).previous(),
                ),
                // প্লে / পজ
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 42,
                    icon: Icon(
                      audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => ref.read(audioPlayerProvider.notifier).playOrPause(),
                  ),
                ),
                // পরবর্তী গান
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
                ),
                // রিপিট বাটন
                IconButton(
                  icon: Icon(
                    audioState.repeatMode == RepeatState.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: audioState.repeatMode != RepeatState.off ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onPressed: () => ref.read(audioPlayerProvider.notifier).toggleRepeat(),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showQueueModal(BuildContext context, AudioPlayerState state, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(vertical: Radius.circular(20)),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("গানের ক্রমতালিকা (Queue)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(color: AppColors.divider),
            Expanded(
              child: ListView.separated(
                itemCount: state.playlist.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (ctx, i) {
                  final item = state.playlist[i];
                  final isCurrent = i == state.currentIndex;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isCurrent ? Icons.volume_up_rounded : Icons.music_note_rounded,
                      color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isCurrent ? AppColors.primary : Colors.white,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(audioPlayerProvider.notifier).playSong(item, customPlaylist: state.playlist);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}