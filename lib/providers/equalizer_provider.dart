import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_player_provider.dart';

class EqualizerState {
  final bool isEnabled;
  final String currentPreset;
  final List<double> bandGains; // 5-Bands (-10.0 to +10.0 dB)
  final double bassBoost; // 0.0 to 100.0%
  final double virtualizer; // 0.0 to 100.0%

  EqualizerState({
    this.isEnabled = true,
    this.currentPreset = 'Normal',
    this.bandGains = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.bassBoost = 0.0,
    this.virtualizer = 0.0,
  });

  EqualizerState copyWith({
    bool? isEnabled,
    String? currentPreset,
    List<double>? bandGains,
    double? bassBoost,
    double? virtualizer,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      currentPreset: currentPreset ?? this.currentPreset,
      bandGains: bandGains ?? this.bandGains,
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
    );
  }
}

class EqualizerNotifier extends StateNotifier<EqualizerState> {
  final Ref ref;

  EqualizerNotifier(this.ref) : super(EqualizerState());

  static const Map<String, List<double>> presets = {
    'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Classical': [4.0, 3.0, -2.0, 2.0, -1.0],
    'Dance': [6.0, 0.0, 2.0, 4.0, 1.0],
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Hip-Hop': [5.0, 3.0, 0.0, 1.0, 3.0],
    'Jazz': [3.0, 2.0, -1.0, 2.0, 4.0],
    'Pop': [-1.0, 2.0, 5.0, 1.0, -2.0],
    'Rock': [5.0, 3.0, -1.0, 3.0, 5.0],
    'Vocal': [-2.0, -1.0, 3.0, 4.0, 1.0],
  };

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    _applyDspFilters();
  }

  void setPreset(String presetName) {
    if (presets.containsKey(presetName)) {
      state = state.copyWith(
        currentPreset: presetName,
        bandGains: List.from(presets[presetName]!),
      );
      _applyDspFilters();
    }
  }

  void setBandGain(int index, double gain) {
    if (index >= 0 && index < 5) {
      final updatedGains = List<double>.from(state.bandGains);
      updatedGains[index] = gain.clamp(-10.0, 10.0);
      state = state.copyWith(
        currentPreset: 'Custom',
        bandGains: updatedGains,
      );
      _applyDspFilters();
    }
  }

  void setBassBoost(double value) {
    state = state.copyWith(bassBoost: value.clamp(0.0, 100.0));
    _applyDspFilters();
  }

  void setVirtualizer(double value) {
    state = state.copyWith(virtualizer: value.clamp(0.0, 100.0));
    _applyDspFilters();
  }

  void resetEqualizer() {
    state = state.copyWith(
      currentPreset: 'Normal',
      bandGains: [0.0, 0.0, 0.0, 0.0, 0.0],
      bassBoost: 0.0,
      virtualizer: 0.0,
    );
    _applyDspFilters();
  }

  /// libmpv-এর FFmpeg lavfi অডিও ফিল্টার পাইপলাইনে রিয়েল-টাইম DSP প্রয়োগ করা
  void _applyDspFilters() {
    try {
      final playerNotifier = ref.read(audioPlayerProvider.notifier);
      final dynamic rawPlayer = (playerNotifier as dynamic)._player;

      if (!state.isEnabled) {
        rawPlayer?.platform?.setProperty('af', '');
        return;
      }

      // ফ্রিকোয়েন্সি ব্যান্ড: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
      final g0 = state.bandGains[0] + (state.bassBoost / 20.0); // বেস বুস্ট লো-ব্যান্ডে যোগ
      final g1 = state.bandGains[1];
      final g2 = state.bandGains[2];
      final g3 = state.bandGains[3];
      final g4 = state.bandGains[4];

      // FFmpeg equalizer filter চেইন
      final filterString =
          'lavfi=[equalizer=f=60:t=q:w=1:g=$g0,equalizer=f=230:t=q:w=1:g=$g1,equalizer=f=910:t=q:w=1:g=$g2,equalizer=f=3600:t=q:w=1:g=$g3,equalizer=f=14000:t=q:w=1:g=$g4]';

      rawPlayer?.platform?.setProperty('af', filterString);
    } catch (_) {
      // অফলাইন প্লেয়ারে ব্যাকগ্রাউন্ড হ্যান্ডলিং
    }
  }
}

final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerState>((ref) {
  return EqualizerNotifier(ref);
});