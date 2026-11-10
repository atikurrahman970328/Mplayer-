import 'package:flutter/services.dart';

class PipController {
  static const MethodChannel _channel = MethodChannel('com.example.offline_mx_player/pip');

  /// অ্যান্ড্রয়েড নেটিভ পিকচার-ইন-পিকচার (PiP) মোড চালু করা
  static Future<bool> enterPictureInPicture() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('enterPiP');
      return result ?? false;
    } on PlatformException {
      // ডিভাইসে PiP সাপোর্ট না থাকলে গ্রেসফুলি হ্যান্ডেল করবে
      return false;
    }
  }

  /// ডিভাইস পিকচার-ইন-পিকচার সমর্থন করে কি না যাচাই করা
  static Future<bool> isPipSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } on PlatformException {
      return false;
    }
  }
}