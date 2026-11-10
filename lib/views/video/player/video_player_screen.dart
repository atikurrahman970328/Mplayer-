import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/media_model.dart';
import '../../../database/db_helper.dart';
import 'widgets/gesture_overlay.dart';
import 'widgets/kids_lock_overlay.dart';
import 'dialogs/decoder_selector_dialog.dart';
import 'dialogs/playback_settings_dialog.dart';
import '../subtitle/subtitle_manager_sheet.dart';
import '../video_info_page.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem media;

  const VideoPlayerScreen({super.key, required this.media});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _showControls = true;
  Timer? _hideTimer;
  bool _isLocked = false;

  // প্লেয়ার সেটিংস স্টেট
  double _volume = 1.0;
  double _brightness = 0.8;
  double _speed = 1.0;
  CustomAspectRatio _aspectRatio = CustomAspectRatio.fit;
  DecoderMode _decoderMode = DecoderMode.hw;

  // HUD ওভারলে স্টেট
  bool _showHud = false;
  String _hudLabel = "";
  IconData _hudIcon = Icons.volume_up;
  double _hudValue = 0.0;
  Timer? _hudTimer;

  // সিক স্টেট
  Duration _currentPos = Duration.zero;
  Duration _totalDur = Duration.zero;

  @override
  void initState() {
    super.initState();

    // ল্যান্ডস্কেপ ও ফুলস্ক্রিন সেটআপ
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // MediaKit প্লেয়ার তৈরি
    _player = Player();
    _controller = VideoController(_player);

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // হার্ডওয়্যার ডিকোড ডিফল্ট অন
    (_player.platform as dynamic)?.setProperty('hwdec', 'mediacodec');

    // প্লেলিস্ট এবং ভিডিও ওপেন
    await _player.open(Media(widget.media.path));

    // পূর্বে দেখা পজিশন থেকে চালু (Resume)
    if (widget.media.lastPositionMs > 0 && widget.media.watchedPercentage < 95.0) {
      await _player.seek(Duration(milliseconds: widget.media.lastPositionMs));
    }

    // পজিশন ও ডুরেশন ট্র্যাকিং স্ট্রিম
    _player.stream.position.listen((pos) {
      if (mounted) setState(() => _currentPos = pos);
    });

    _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _totalDur = dur);
    });

    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  void _displayHud(IconData icon, String label, double value) {
    _hudTimer?.cancel();
    setState(() {
      _showHud = true;
      _hudIcon = icon;
      _hudLabel = label;
      _hudValue = value;
    });
    _hudTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showHud = false);
    });
  }

  void _savePlaybackProgress() async {
    if (_totalDur.inMilliseconds <= 0) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final percentage = (_currentPos.inMilliseconds / _totalDur.inMilliseconds) * 100;

      await db.insert(
        'playback_history',
        {
          'file_path': widget.media.path,
          'media_type': 'video',
          'last_position_ms': _currentPos.inMilliseconds,
          'total_duration_ms': _totalDur.inMilliseconds,
          'watched_percentage': percentage,
          'last_played_timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _savePlaybackProgress();
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _player.dispose();

    // স্ক্রিন ব্যাক টু নরমাল
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  BoxFit _getBoxFit() {
    switch (_aspectRatio) {
      case CustomAspectRatio.fit:
        return BoxFit.contain;
      case CustomAspectRatio.stretch:
        return BoxFit.fill;
      case CustomAspectRatio.crop:
        return BoxFit.cover;
      case CustomAspectRatio.ratio16_9:
      case CustomAspectRatio.ratio4_3:
      case CustomAspectRatio.ratio1_1:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ১. মূল ভিডিও রেন্ডার এরিয়া
          Center(
            child: Video(
              controller: _controller,
              fit: _getBoxFit(),
              controls: NoVideoControls,
            ),
          ),

          // ২. ব্রাইটনেস ওভারলে ফিল্টার
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: (1.0 - _brightness).clamp(0.0, 0.85)),
            ),
          ),

          // ৩. জেসচার ডিটেক্টর ও সোয়াইপ কন্ট্রোল
          if (!_isLocked)
            GestureOverlay(
              onSingleTap: _toggleControls,
              onDoubleTapCenter: () => _player.playOrPause(),
              onDoubleTapLeft: () {
                final target = _currentPos - const Duration(seconds: 10);
                _player.seek(target < Duration.zero ? Duration.zero : target);
                _displayHud(Icons.fast_rewind_rounded, "-10s", 0.5);
              },
              onDoubleTapRight: () {
                final target = _currentPos + const Duration(seconds: 10);
                _player.seek(target > _totalDur ? _totalDur : target);
                _displayHud(Icons.fast_forward_rounded, "+10s", 0.5);
              },
              onVolumeDelta: (delta) {
                setState(() {
                  _volume = (_volume + delta).clamp(0.0, 1.0);
                  _player.setVolume((_volume * 100));
                });
                _displayHud(
                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                  "Volume: ${(_volume * 100).round()}%",
                  _volume,
                );
              },
              onBrightnessDelta: (delta) {
                setState(() {
                  _brightness = (_brightness + delta).clamp(0.1, 1.0);
                });
                _displayHud(
                  Icons.brightness_6_rounded,
                  "Brightness: ${(_brightness * 100).round()}%",
                  _brightness,
                );
              },
              onSeekDelta: (delta) {
                final target = _currentPos + delta;
                _displayHud(
                  delta.isNegative ? Icons.fast_rewind : Icons.fast_forward,
                  "${target.inMinutes}:${(target.inSeconds % 60).toString().padLeft(2, '0')}",
                  (target.inMilliseconds / (_totalDur.inMilliseconds == 0 ? 1 : _totalDur.inMilliseconds))
                      .clamp(0.0, 1.0),
                );
              },
              onSeekCommit: () {},
              child: Container(color: Colors.transparent),
            ),

          // ৪. HUD পপআপ (Volume/Brightness/Seek Indicator)
          if (_showHud)
            GestureIndicatorHUD(icon: _hudIcon, label: _hudLabel, value: _hudValue),

          // ৫. কিডস লক ওভারলে
          if (_isLocked)
            KidsLockOverlay(
              onUnlock: () => setState(() {
                _isLocked = false;
                _showControls = true;
                _startHideControlsTimer();
              }),
            ),

          // ৬. প্লেব্যাক কন্ট্রোল ইউআই (Top Bar & Bottom Bar)
          if (_showControls && !_isLocked) ...[
            _buildTopBar(),
            _buildBottomBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.media.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              // ডিকোডার বাটন (HW / SW)
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DecoderSelectorDialog(
                      currentMode: _decoderMode,
                      onSelected: (mode) {
                        setState(() => _decoderMode = mode);
                        if (mode == DecoderMode.sw) {
                          (_player.platform as dynamic)?.setProperty('hwdec', 'no');
                        } else {
                          (_player.platform as dynamic)?.setProperty('hwdec', 'mediacodec');
                        }
                      },
                    ),
                  );
                },
                child: Text(
                  _decoderMode == DecoderMode.hw ? "HW" : _decoderMode == DecoderMode.hwPlus ? "HW+" : "SW",
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              // সাবটাইটেল বাটন
              IconButton(
                icon: const Icon(Icons.subtitles_rounded, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SubtitleManagerSheet(
                      player: _player,
                      videoPath: widget.media.path,
                      onDelayChanged: (delay) {
                        (_player.platform as dynamic)?.setProperty('sub-delay', '$delay');
                      },
                    ),
                  );
                },
              ),
              // ভিডিও ইনফো
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoInfoPage(media: widget.media)),
                  );
                },
              ),
              // কিডস লক বাটন
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _isLocked = true;
                  _showControls = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final formatTime = (Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return d.inHours > 0 ? "${d.inHours}:$m:$s" : "$m:$s";
    };

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // সিকবার ও সময়
              Row(
                children: [
                  Text(formatTime(_currentPos), style: const TextStyle(color: Colors.white, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        thumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                      ),
                      child: Slider(
                        value: _currentPos.inMilliseconds
                            .toDouble()
                            .clamp(0.0, _totalDur.inMilliseconds.toDouble() > 0 ? _totalDur.inMilliseconds.toDouble() : 1.0),
                        max: _totalDur.inMilliseconds.toDouble() > 0 ? _totalDur.inMilliseconds.toDouble() : 1.0,
                        onChanged: (val) {
                          _startHideControlsTimer();
                          _player.seek(Duration(milliseconds: val.round()));
                        },
                      ),
                    ),
                  ),
                  Text(formatTime(_totalDur), style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
              // মূল প্লে কন্ট্রোল বাটন
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // সেটিংস (Speed & Ratio)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PlaybackSettingsDialog(
                          currentSpeed: _speed,
                          currentRatio: _aspectRatio,
                          onSpeedChanged: (spd) {
                            setState(() => _speed = spd);
                            _player.setRate(spd);
                          },
                          onRatioChanged: (ratio) => setState(() => _aspectRatio = ratio),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      // ১০ সেকেন্ড রিওয়াইন্ড
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          _startHideControlsTimer();
                          _player.seek(_currentPos - const Duration(seconds: 10));
                        },
                      ),
                      // প্লে / পজ
                      StreamBuilder<bool>(
                        stream: _player.stream.playing,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? true;
                          return IconButton(
                            iconSize: 42,
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              _startHideControlsTimer();
                              _player.playOrPause();
                            },
                          );
                        },
                      ),
                      // ১০ সেকেন্ড ফরোয়ার্ড
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          _startHideControlsTimer();
                          _player.seek(_currentPos + const Duration(seconds: 10));
                        },
                      ),
                    ],
                  ),
                  // স্ক্রিন রোটেশন / ফুলস্ক্রিন টগল
                  IconButton(
                    icon: const Icon(Icons.screen_rotation_rounded, color: Colors.white),
                    onPressed: () {
                      final currentOrientation = MediaQuery.of(context).orientation;
                      if (currentOrientation == Orientation.landscape) {
                        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}