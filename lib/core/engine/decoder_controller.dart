import 'package:media_kit/media_kit.dart';

enum DecoderMode { hw, hwPlus, sw }

class DecoderController {
  /// প্লেয়ার ইনস্ট্যান্স তৈরি এবং কনফিগারেশন
  static Player createConfiguredPlayer({DecoderMode defaultMode = DecoderMode.hw}) {
    final player = Player(
      configuration: const PlayerConfiguration(
        ready: true,
        bufferSize: 32 * 1024 * 1024, // ৩২ মেগাবাইট অফলাইন বাফার
      ),
    );
    applyDecoderMode(player, defaultMode);
    return player;
  }

  /// ভিডিও চলাকালীন সময়ে ডিকোডার মোড পরিবর্তন করার মেথড
  static void applyDecoderMode(Player player, DecoderMode mode) {
    try {
      final dynamic rawPlatform = player.platform;

      switch (mode) {
        case DecoderMode.hw:
          // Android Native Mediacodec (হার্ডওয়্যার অ্যাকসিলারেশন - ব্যাটারি সাশ্রয়ী)
          rawPlatform?.setProperty('hwdec', 'mediacodec');
          break;

        case DecoderMode.hwPlus:
          // Mediacodec-Copy (জিপিইউ ফ্রেম পাইপলাইন সহ অতিরিক্ত কোডেক সাপোর্ট)
          rawPlatform?.setProperty('hwdec', 'mediacodec-copy');
          break;

        case DecoderMode.sw:
          // Pure Software Rendering (FFmpeg ভিত্তিক সফটওয়্যার ডিকোডার)
          rawPlatform?.setProperty('hwdec', 'no');
          break;
      }
    } catch (_) {
      // ডিভাইসে প্রোপার্টি সেট না হলে ডিফল্ট হ্যান্ডলিং
    }
  }

  /// ডিকোডার মোডের টেক্সট নাম
  static String getModeTitle(DecoderMode mode) {
    switch (mode) {
      case DecoderMode.hw:
        return "HW";
      case DecoderMode.hwPlus:
        return "HW+";
      case DecoderMode.sw:
        return "SW";
    }
  }
}