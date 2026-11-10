import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  static const List<Color> accentColors = [
    Color(0xFF007AFF), // MX Classic Blue
    Color(0xFF00E676), // Emerald Green
    Color(0xFFFF9100), // Amber Sunset
    Color(0xFFD500F9), // Purple Neon
    Color(0xFFFF1744), // Crimson Red
    Color(0xFF00E5FF), // Cyan Ocean
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("থিম ও ভিজ্যুয়াল সেটিংস (Themes)"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "থিম মোড (Theme Mode)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildThemeCard(
            context,
            title: "AMOLED Pure Black (ব্যাটারি সাশ্রয়ী)",
            subtitle: "পিউর ব্ল্যাক ও উচ্চ কনট্রাস্টযুক্ত ডিসপ্লে",
            isSelected: currentTheme.themeType == AppThemeType.amoledBlack,
            onTap: () => themeNotifier.setThemeType(AppThemeType.amoledBlack),
          ),
          const SizedBox(height: 10),
          _buildThemeCard(
            context,
            title: "Dark Slate Theme",
            subtitle: "ক্লাসিক ডার্ক গ্রে ব্যাকগ্রাউন্ড",
            isSelected: currentTheme.themeType == AppThemeType.dark,
            onTap: () => themeNotifier.setThemeType(AppThemeType.dark),
          ),
          const SizedBox(height: 10),
          _buildThemeCard(
            context,
            title: "Light Mode",
            subtitle: "উজ্জ্বল ও পরিষ্কার ইন্টারফেস",
            isSelected: currentTheme.themeType == AppThemeType.light,
            onTap: () => themeNotifier.setThemeType(AppThemeType.light),
          ),
          const SizedBox(height: 28),
          const Text(
            "অ্যাকসেন্ট কালার (Accent Palette)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: accentColors.map((color) {
              final isChosen = currentTheme.accentColor.value == color.value;
              return GestureDetector(
                onTap: () => themeNotifier.setAccentColor(color),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? Colors.white : Colors.transparent,
                      width: 3.5,
                    ),
                    boxShadow: [
                      if (isChosen)
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isChosen ? const Icon(Icons.check, color: Colors.white, size: 26) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}