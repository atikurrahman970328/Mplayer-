import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum DecoderMode { hw, hwPlus, sw }

class DecoderSelectorDialog extends StatelessWidget {
  final DecoderMode currentMode;
  final Function(DecoderMode) onSelected;

  const DecoderSelectorDialog({
    super.key,
    required this.currentMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Row(
        children: [
          Icon(Icons.memory_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text("ডিকোডার নির্বাচন (Decoder Mode)", style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            mode: DecoderMode.hw,
            title: "HW Decoder (Hardware)",
            subtitle: "ডিভাইসের চিপসেট ব্যবহার করে, ব্যাটারি সাশ্রয়ী ও দ্রুততম।",
          ),
          const Divider(color: AppColors.divider),
          _buildOption(
            context,
            mode: DecoderMode.hwPlus,
            title: "HW+ Decoder (Hardware Extended)",
            subtitle: "উন্নত গ্রাফিক্স পাইপলাইন সহ অতিরিক্ত ভিডিও কোডেক সমর্থন করে।",
          ),
          const Divider(color: AppColors.divider),
          _buildOption(
            context,
            mode: DecoderMode.sw,
            title: "SW Decoder (Software / FFmpeg)",
            subtitle: "সফটওয়্যার ডিকোডিং। যেকোনো ক্ষতিগ্রস্ত বা অপ্রচলিত ফরম্যাট প্লে করতে সক্ষম।",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("বন্ধ করুন", style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required DecoderMode mode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () {
        onSelected(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}