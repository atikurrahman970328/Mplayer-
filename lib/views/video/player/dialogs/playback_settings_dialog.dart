import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum CustomAspectRatio { fit, stretch, crop, ratio16_9, ratio4_3, ratio1_1 }

class PlaybackSettingsDialog extends StatelessWidget {
  final double currentSpeed;
  final CustomAspectRatio currentRatio;
  final Function(double) onSpeedChanged;
  final Function(CustomAspectRatio) onRatioChanged;

  const PlaybackSettingsDialog({
    super.key,
    required this.currentSpeed,
    required this.currentRatio,
    required this.onSpeedChanged,
    required this.onRatioChanged,
  });

  static const List<double> speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        contentPadding: EdgeInsets.zero,
        title: const TabBar(
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: "গতি (Speed)"),
            Tab(text: "অনুপাত (Ratio)"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 260,
          child: TabBarView(
            children: [
              // স্পিড কন্ট্রোল ট্যাব
              ListView.builder(
                itemCount: speeds.length,
                itemBuilder: (context, i) {
                  final s = speeds[i];
                  final isSelected = currentSpeed == s;
                  return ListTile(
                    dense: true,
                    title: Text(
                      "${s}x ${s == 1.0 ? '(Normal)' : ''}",
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      onSpeedChanged(s);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              // এসপেক্ট রেশিও ট্যাব
              ListView(
                children: [
                  _buildRatioTile(context, CustomAspectRatio.fit, "স্ক্রিনে ফিট করুন (Fit to Screen)"),
                  _buildRatioTile(context, CustomAspectRatio.stretch, "টেনে বড় করুন (Stretch)"),
                  _buildRatioTile(context, CustomAspectRatio.crop, "জুম ও ক্রপ (Crop)"),
                  _buildRatioTile(context, CustomAspectRatio.ratio16_9, "16:9 ওয়াইডস্ক্রিন"),
                  _buildRatioTile(context, CustomAspectRatio.ratio4_3, "4:3 স্ট্যান্ডার্ড"),
                  _buildRatioTile(context, CustomAspectRatio.ratio1_1, "1:1 স্কয়ার"),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বন্ধ করুন", style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioTile(BuildContext context, CustomAspectRatio ratio, String label) {
    final isSelected = currentRatio == ratio;
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        onRatioChanged(ratio);
        Navigator.pop(context);
      },
    );
  }
}