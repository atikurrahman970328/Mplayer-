import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/sleep_timer_provider.dart';

class SleepTimerDialog extends ConsumerStatefulWidget {
  const SleepTimerDialog({super.key});

  @override
  ConsumerState<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends ConsumerState<SleepTimerDialog> {
  int _selectedMinutes = 30;
  bool _stopAfterCurrent = false;
  bool _fadeOutAudio = true;

  static const List<int> presetMinutes = [5, 10, 15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);
    final timerNotifier = ref.read(sleepTimerProvider.notifier);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.bedtime_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text("স্লিপ টাইমার (Sleep Timer)", style: TextStyle(fontSize: 16)),
        ],
      ),
      content: timerState.isActive
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text("প্লেব্যাক স্বয়ংক্রিয়ভাবে বন্ধ হতে বাকি:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 14),
                Text(
                  timerState.formattedRemaining,
                  style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  label: const Text("টাইমার বন্ধ করুন", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    timerNotifier.cancelTimer();
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetMinutes.map((m) {
                    final isSelected = _selectedMinutes == m;
                    return ChoiceChip(
                      label: Text("$m মি."),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedMinutes = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text("ধীরে ধীরে ভলিউম কমবে (Fade Out)", style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: _fadeOutAudio,
                  onChanged: (val) => setState(() => _fadeOutAudio = val ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text("চলতি গান শেষ হলে বন্ধ করুন", style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: _stopAfterCurrent,
                  onChanged: (val) => setState(() => _stopAfterCurrent = val ?? false),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("বাতিল", style: TextStyle(color: AppColors.textSecondary)),
        ),
        if (!timerState.isActive)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              timerNotifier.startTimer(
                minutes: _selectedMinutes,
                stopAfterCurrent: _stopAfterCurrent,
                fadeOutAudio: _fadeOutAudio,
              );
              Navigator.pop(context);
            },
            child: const Text("চালু করুন", style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}