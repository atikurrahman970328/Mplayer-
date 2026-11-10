import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/equalizer_provider.dart';

class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  static const List<String> bandLabels = ["60 Hz", "230 Hz", "910 Hz", "3.6 kHz", "14 kHz"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("অডিও ইকুয়ালাইজার (Equalizer)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Switch(
            value: eqState.isEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) => eqNotifier.toggleEnabled(val),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Reset All",
            onPressed: () => eqNotifier.resetEqualizer(),
          ),
        ],
      ),
      body: Opacity(
        opacity: eqState.isEnabled ? 1.0 : 0.4,
        child: IgnorePointer(
          ignoring: !eqState.isEnabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. প্রিসেট ড্রপডাউন চিপস
                const Text("সাউন্ড প্রিসেট (Presets)", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...EqualizerNotifier.presets.keys.map((preset) {
                        final isSelected = eqState.currentPreset == preset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(preset),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => eqNotifier.setPreset(preset),
                          ),
                        );
                      }),
                      if (eqState.currentPreset == 'Custom')
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text("Custom"),
                            backgroundColor: AppColors.accent,
                            labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ২. ৫-ব্যান্ড স্লাইডার গ্রিড
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(5, (index) {
                          final gain = eqState.bandGains[index];
                          return Column(
                            children: [
                              Text(
                                "${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB",
                                style: TextStyle(
                                  color: gain == 0 ? AppColors.textSecondary : AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 160,
                                child: RotatedBox(
                                  quarterTurns: 3, // ভার্টিক্যাল স্লাইডার
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                      thumbColor: AppColors.primary,
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor: AppColors.surfaceLight,
                                    ),
                                    child: Slider(
                                      value: gain,
                                      min: -10.0,
                                      max: 10.0,
                                      onChanged: (val) => eqNotifier.setBandGain(index, val),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bandLabels[index],
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ৩. বেস বুস্ট ও ভার্চুয়ালাইজার কন্ট্রোল
                Row(
                  children: [
                    Expanded(
                      child: _buildDialCard(
                        title: "বেস বুস্ট (Bass Boost)",
                        value: eqState.bassBoost,
                        icon: Icons.speaker_group_rounded,
                        color: AppColors.primary,
                        onChanged: (val) => eqNotifier.setBassBoost(val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDialCard(
                        title: "ভার্চুয়ালাইজার (3D Sound)",
                        value: eqState.virtualizer,
                        icon: Icons.surround_sound_rounded,
                        color: AppColors.activeGreen,
                        onChanged: (val) => eqNotifier.setVirtualizer(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "${value.round()}%",
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: AppColors.surfaceLight,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 100.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}