import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/media_constants.dart';

class SubtitleManagerSheet extends StatefulWidget {
  final Player player;
  final String videoPath;
  final Function(double delaySeconds) onDelayChanged;

  const SubtitleManagerSheet({
    super.key,
    required this.player,
    required this.videoPath,
    required this.onDelayChanged,
  });

  @override
  State<SubtitleManagerSheet> createState() => _SubtitleManagerSheetState();
}

class _SubtitleManagerSheetState extends State<SubtitleManagerSheet> {
  double _syncOffsetSeconds = 0.0;
  List<File> _localSubtitles = [];

  @override
  void initState() {
    super.initState();
    _findLocalSubtitles();
  }

  /// ভিডিওর ফোল্ডারে থাকা সব সাবটাইটেল স্বয়ংক্রিয়ভাবে স্ক্যান করা
  void _findLocalSubtitles() {
    try {
      final videoDir = Directory(p.dirname(widget.videoPath));
      if (videoDir.existsSync()) {
        final files = videoDir.listSync().whereType<File>().where((file) {
          final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
          return MediaConstants.supportedSubtitleExtensions.contains(ext);
        }).toList();

        setState(() => _localSubtitles = files);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.player.state.tracks.subtitle;
    final currentTrack = widget.player.state.track.subtitle;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.subtitles_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "সাবটাইটেল ব্যবস্থাপনা (Subtitles)",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.divider),

            // ১. এমবেডেড সাবটাইটেল ট্র্যাক তালিকা
            const Text("অন্তর্ভুক্ত ট্র্যাক (Embedded Tracks)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            ListTile(
              dense: true,
              leading: Icon(
                currentTrack.id == 'no' ? Icons.radio_button_checked : Icons.radio_button_off,
                color: currentTrack.id == 'no' ? AppColors.primary : AppColors.textSecondary,
              ),
              title: const Text("সাবটাইটেল বন্ধ (Disable)", style: TextStyle(color: Colors.white)),
              onTap: () {
                widget.player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
              },
            ),
            ...tracks.map((t) {
              final isSelected = currentTrack.id == t.id;
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(t.title ?? t.language ?? "Track ${t.id}", style: const TextStyle(color: Colors.white)),
                onTap: () {
                  widget.player.setSubtitleTrack(t);
                  Navigator.pop(context);
                },
              );
            }),

            const SizedBox(height: 12),
            // ২. লোকাল স্টোরেজ থেকে এক্সটারনাল সাবটাইটেল
            if (_localSubtitles.isNotEmpty) ...[
              const Text("ফোল্ডারের সাবটাইটেল ফাইল", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ..._localSubtitles.map((file) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.file_present_rounded, color: AppColors.accent),
                  title: Text(p.basename(file.path), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () {
                    widget.player.setSubtitleTrack(SubtitleTrack.uri(file.path));
                    Navigator.pop(context);
                  },
                );
              }),
            ],

            const Divider(color: AppColors.divider),
            // ৩. সাবটাইটেল সিঙ্ক্রোনাইজেশন (Delay Adjustment)
            const Text("সাবটাইটেল সিঙ্ক (Subtitle Delay)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSyncBtn("-0.5s", -0.5),
                _buildSyncBtn("-0.1s", -0.1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "${_syncOffsetSeconds >= 0 ? '+' : ''}${_syncOffsetSeconds.toStringAsFixed(1)} s",
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildSyncBtn("+0.1s", 0.1),
                _buildSyncBtn("+0.5s", 0.5),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _syncOffsetSeconds = 0.0);
                  widget.onDelayChanged(0.0);
                },
                child: const Text("রিসেট (Reset Sync)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBtn(String text, double delta) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
      ),
      onPressed: () {
        setState(() => _syncOffsetSeconds += delta);
        widget.onDelayChanged(_syncOffsetSeconds);
      },
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}