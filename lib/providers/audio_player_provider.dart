import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../models/media_model.dart';
import '../database/db_helper.dart';

enum RepeatState { off, all, one }

class AudioPlayerState {
  final MediaItem? currentSong;
  final List<MediaItem> playlist;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffle;
  final RepeatState repeatMode;

  AudioPlayerState({
    this.currentSong,
    this.playlist = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffle = false,
    this.repeatMode = RepeatState.off,
  });

  AudioPlayerState copyWith({
    MediaItem? currentSong,
    List<MediaItem>? playlist,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isShuffle,
    RepeatState? repeatMode,
  }) {
    return AudioPlayerState(
      currentSong: currentSong ?? this.currentSong,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  late final Player _player;

  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _player = Player();
    _initStreams();
  }

  void _initStreams() {
    _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _handleTrackCompletion();
      }
    });
  }

  Future<void> playSong(MediaItem song, {List<MediaItem>? customPlaylist}) async {
    final list = customPlaylist ?? [song];
    final index = list.indexWhere((e) => e.path == song.path);

    state = state.copyWith(
      playlist: list,
      currentIndex: index >= 0 ? index : 0,
      currentSong: song,
      position: Duration.zero,
    );

    await _player.open(Media(song.path));
    await _player.play();

    // প্লেব্যাক হিস্ট্রি আপডেট
    _saveAudioHistory(song);
  }

  void playOrPause() {
    _player.playOrPause();
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void next() {
    if (state.playlist.isEmpty) return;

    int nextIndex;
    if (state.isShuffle) {
      nextIndex = Random().nextInt(state.playlist.length);
    } else {
      nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.playlist.length) {
        if (state.repeatMode == RepeatState.all) {
          nextIndex = 0;
        } else {
          return; // প্লেলিস্ট সমাপ্ত
        }
      }
    }

    playSong(state.playlist[nextIndex], customPlaylist: state.playlist);
  }

  void previous() {
    if (state.playlist.isEmpty) return;

    if (state.position.inSeconds > 3) {
      // ৩ সেকেন্ডের বেশি চললে প্রথম থেকে শুরু
      seek(Duration.zero);
      return;
    }

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.playlist.length - 1;
    }

    playSong(state.playlist[prevIndex], customPlaylist: state.playlist);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleRepeat() {
    RepeatState nextMode;
    switch (state.repeatMode) {
      case RepeatState.off:
        nextMode = RepeatState.all;
        break;
      case RepeatState.all:
        nextMode = RepeatState.one;
        break;
      case RepeatState.one:
        nextMode = RepeatState.off;
        break;
    }
    state = state.copyWith(repeatMode: nextMode);
  }

  void _handleTrackCompletion() {
    if (state.repeatMode == RepeatState.one) {
      seek(Duration.zero);
      _player.play();
    } else {
      next();
    }
  }

  void _saveAudioHistory(MediaItem song) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'playback_history',
        {
          'file_path': song.path,
          'media_type': 'audio',
          'last_position_ms': 0,
          'total_duration_ms': song.durationMs,
          'watched_percentage': 0.0,
          'last_played_timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});