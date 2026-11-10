// ==========================================
// File: lib/main.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

// ডাটাবেজ ও থিম ইম্পোর্ট
import 'database/db_helper.dart';
import 'providers/theme_provider.dart';

// পেজ ইম্পোর্ট
import 'views/splash/splash_screen.dart';
import 'views/home/home_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ১. LibMPV ডিকোডার ইঞ্জিন ইনিশিয়ালাইজেশন (অফলাইন HW/SW প্লেব্যাক)
  MediaKit.ensureInitialized();

  // ২. ডিভাইস মেমোরিতে SQLite ডাটাবেজ সেশন লোড করা
  await DatabaseHelper.instance.database;

  // ৩. ট্রান্সপারেন্ট স্ট্যাটাসবার ও নেভিগেশন বার সেটআপ
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: OfflineMXPlayerApp(),
    ),
  );
}

class OfflineMXPlayerApp extends ConsumerWidget {
  const OfflineMXPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ধাপ ৭ এর থিম স্টেট পর্যবেক্ষণ (AMOLED Black, Dark, Light এবং Accent Color)
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'MX Player Offline',
      debugShowCheckedModeBanner: false,
      theme: themeState.themeData,
      // স্প্ল্যাশ স্ক্রিন চালু হবে এবং স্ক্যান শেষ হলে হোম ড্যাশবোর্ডে যাবে
      home: const SplashScreen(
        nextScreen: HomeDashboard(),
      ),
    );
  }
}