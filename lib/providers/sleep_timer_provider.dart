import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_player_provider.dart';

class SleepTimerState {
  final bool isActive;
  final int totalSeconds;
  final int remainingSeconds;
  final bool stopAfterCurrent;
  final bool fadeOutAudio;

  SleepTimerState({
    this.isActive = false,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.stopAfterCurrent = false,
    this.fadeOutAudio = true,
  });

  String get formattedRemaining {
    if (remainingSeconds <= 0) return "00:00";
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  SleepTimerState copyWith({
    bool? isActive,
    int? totalSeconds,
    int? remainingSeconds,
    bool? stopAfterCurrent,
    bool? fadeOutAudio,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      stopAfterCurrent: stopAfterCurrent ?? this.stopAfterCurrent,
      fadeOutAudio: fadeOutAudio ?? this.fadeOutAudio,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref ref;
  Timer? _countdownTimer;

  SleepTimerNotifier(this.ref) : super(SleepTimerState());

  void startTimer({
    required int minutes,
    required bool stopAfterCurrent,
    required bool fadeOutAudio,
  }) {
    _countdownTimer?.cancel();
    final totalSec = minutes * 60;

    state = state.copyWith(
      isActive: true,
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
      stopAfterCurrent: stopAfterCurrent,
      fadeOutAudio: fadeOutAudio,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        cancelTimer();
        _executeSleepAction();
      }
    });
  }

  void cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(
      isActive: false,
      totalSeconds: 0,
      remainingSeconds: 0,
    );
  }

  void _executeSleepAction() async {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    // অডিও ধীরে ধীরে ফেড আউট (Fade out)
    if (state.fadeOutAudio) {
      try {
        final dynamic rawPlayer = (audioNotifier as dynamic)._player;
        for (int i = 80; i >= 0; i -= 20) {
          rawPlayer?.setVolume(i.toDouble());
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (_) {}
    }

    // প্লেব্যাক বন্ধ করা
    audioNotifier.playOrPause();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider = StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});