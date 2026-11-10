import 'package:sqflite/sqflite.dart';
import '../../database/db_helper.dart';

class PlaybackHistoryService {
  /// প্লেব্যাক অবস্থান এবং দেখার শতাংশ লোকাল SQLite ডাটাবেজে সংরক্ষণ
  static Future<void> saveProgress({
    required String filePath,
    required String mediaType, // 'video' অথবা 'audio'
    required Duration currentPosition,
    required Duration totalDuration,
  }) async {
    final int currentMs = currentPosition.inMilliseconds;
    final int totalMs = totalDuration.inMilliseconds;

    if (totalMs <= 0) return;

    final double watchedPercentage = (currentMs / totalMs) * 100;

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'playback_history',
        {
          'file_path': filePath,
          'media_type': mediaType,
          'last_position_ms': currentMs,
          'total_duration_ms': totalMs,
          'watched_percentage': watchedPercentage,
          'last_played_timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// পূর্বের দেখার পজিশন উদ্ধার করা (৯৫% এর বেশি দেখা হয়ে গেলে শুরু থেকে চালু হবে)
  static Future<int> getResumePosition(String filePath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'playback_history',
        columns: ['last_position_ms', 'watched_percentage'],
        where: 'file_path = ?',
        whereArgs: [filePath],
      );

      if (maps.isNotEmpty) {
        final percentage = (maps.first['watched_percentage'] as num).toDouble();
        if (percentage < 95.0) {
          return maps.first['last_position_ms'] as int;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// নির্দিষ্ট কোনো হিস্ট্রি মুছে ফেলা
  static Future<void> deleteHistoryItem(String filePath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'playback_history',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );
    } catch (_) {}
  }

  /// সম্পূর্ণ হিস্ট্রি ক্লিয়ার করা
  static Future<void> clearAllHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('playback_history');
    } catch (_) {}
  }
}