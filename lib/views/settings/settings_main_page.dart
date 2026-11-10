import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/db_helper.dart';
import '../../providers/media_scan_provider.dart';
import '../audio/equalizer_page.dart';
import '../tools/storage_analyzer_page.dart';
import 'theme_settings_page.dart';
import 'app_info_page.dart';

class SettingsMainPage extends ConsumerWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("সেটিংস হাব (Settings)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader("ভিজ্যুয়াল ও চেহারা (Appearance)"),
          ListTile(
            leading: const Icon(Icons.palette_rounded, color: AppColors.primary),
            title: const Text("থিম ও অ্যাকসেন্ট কাস্টমাইজেশন", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("Pure AMOLED Black, Dark, Light এবং কালার প্যালেট", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsPage())),
          ),
          const Divider(color: AppColors.divider),

          _buildSectionHeader("ভিডিও প্লেয়ার সেটিংস (Video Player)"),
          ListTile(
            leading: const Icon(Icons.memory_rounded, color: AppColors.accent),
            title: const Text("ডিফল্ট ডিকোডার মোড", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("Hardware (HW) হার্ডওয়্যার অ্যাকসিলারেশন নির্বাচিত", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
          ListTile(
            leading: const Icon(Icons.aspect_ratio_rounded, color: AppColors.accent),
            title: const Text("ডিফল্ট এসপেক্ট রেশিও", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("Fit to Screen (প্রয়োজনে ক্রপ/স্ট্রেচ)", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
          ListTile(
            leading: const Icon(Icons.screen_lock_rotation_rounded, color: AppColors.accent),
            title: const Text("ভিডিও প্লেব্যাক অটো-ল্যান্ডস্কেপ", style: TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Switch(value: true, activeColor: AppColors.primary, onChanged: (_) {}),
          ),
          const Divider(color: AppColors.divider),

          _buildSectionHeader("অডিও ও সাউন্ড ইঞ্জিন (Audio & DSP)"),
          ListTile(
            leading: const Icon(Icons.graphic_eq_rounded, color: AppColors.activeGreen),
            title: const Text("ইকুয়ালাইজার ও অডিও ফিল্টার", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("5-ব্যান্ড টিউনিং, বেস বুস্ট ও থ্রি-ডি সাউন্ড", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerPage())),
          ),
          ListTile(
            leading: const Icon(Icons.headset_rounded, color: AppColors.activeGreen),
            title: const Text("হেডফোন খুললে প্লেব্যাক পজ হবে", style: TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Switch(value: true, activeColor: AppColors.primary, onChanged: (_) {}),
          ),
          const Divider(color: AppColors.divider),

          _buildSectionHeader("স্টোরেজ ও মেমোরি বিশ্লেষণ (Tools)"),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amberAccent),
            title: const Text("স্টোরেজ অ্যানালাইজার", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("বড় ফাইল ও ডুপ্লিকেট মিডিয়া মুছে মেমোরি খালি করুন", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageAnalyzerPage())),
          ),
          const Divider(color: AppColors.divider),

          _buildSectionHeader("প্রাইভেসি ও লোকাল ডাটা (Privacy)"),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.errorRed),
            title: const Text("প্লেব্যাক হিস্ট্রি ক্লিয়ার করুন", style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('playback_history');
              ref.read(mediaProvider.notifier).initAndScan();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("হিস্ট্রি সম্পূর্ণ মোছা হয়েছে")));
            },
          ),
          const Divider(color: AppColors.divider),

          _buildSectionHeader("সম্পর্কে (About)"),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Colors.grey),
            title: const Text("অ্যাপের বিস্তারিত ও ওপেন-সোর্স লাইসেন্স", style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text("v1.0.0 (100% Offline Architecture)", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoPage())),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }
}