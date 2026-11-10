import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("অ্যাপ পরিচিতি (App Info)"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 55, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "MX Player Offline",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Version 1.0.0 • Build 2026.1",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // প্রাইভেসি ও অফলাইন প্রতিশ্রুতি কার্ড
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.activeGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, color: AppColors.activeGreen, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "১০০% অফলাইন নিশ্চয়তা (Zero Cloud)",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "এই অ্যাপ্লিকেশনটিতে কোনো সার্ভার, ক্লাউড কানেকশন বা ইন্টারনেট ট্র্যাকিং নেই। আপনার সমস্ত ভিডিও, গান, প্লেলিস্ট এবং প্রাইভেট ভল্ট ফাইল শুধুই আপনার ডিভাইসে সুরক্ষিত থাকে।",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("ব্যবহৃত কোর প্রযুক্তি ও লাইসেন্স", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _buildTechCard("LibMPV & FFmpeg Engine", "হার্ডওয়্যার ডিকোডিং এবং মাল্টি-কোডেক সমর্থনকারী প্লেব্যাক কোর।"),
          _buildTechCard("MediaKit", "ফ্লাটারের জন্য পারফরম্যান্স-অপ্টিমাইজড ভিডিও ও অডিও রেন্ডারিং ফ্রেমওয়ার্ক।"),
          _buildTechCard("SQLite Database", "ডিভাইসের ভেতর সম্পূর্ণ অফলাইন হিস্ট্রি, প্লেলিস্ট ও ফেভারিট সংরক্ষণকারী রিলেশনাল ডাটাবেজ।"),
          _buildTechCard("AES-256 Bit Encryption", "ব্যক্তিগত ভল্টের ফাইল সামরিক-গ্রেডের সুরক্ষায় এনক্রিপ্ট করার অ্যালগরিদম।"),
        ],
      ),
    );
  }

  Widget _buildTechCard(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}