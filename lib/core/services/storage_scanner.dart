import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../models/media_model.dart';
import '../../models/folder_model.dart';
import '../constants/media_constants.dart';
import '../../database/db_helper.dart';

class StorageScanResult {
  final List<MediaItem> videos;
  final List<MediaItem> audios;
  final List<MediaFolder> videoFolders;
  final List<MediaFolder> audioFolders;

  StorageScanResult({
    required this.videos,
    required this.audios,
    required this.videoFolders,
    required this.audioFolders,
  });
}

class StorageScanner {
  /// পারমিশন যাচাই করা
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Android 11+ এর জন্য Manage Storage
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      // Android 13+ এর মিডিয়া পারমিশন
      final videoStatus = await Permission.videos.request();
      final audioStatus = await Permission.audio.request();
      if (videoStatus.isGranted || audioStatus.isGranted) return true;

      // লিগ্যাসি পারমিশন
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return false;
  }

  /// সম্পূর্ণ অফলাইন স্টোরেজ স্ক্যান
  static Future<StorageScanResult> scanDeviceStorage() async {
    final List<MediaItem> allVideos = [];
    final List<MediaItem> allAudios = [];
    
    // হিস্ট্রি এবং ফেভারিট ডাটা ক্যাশ লোড করা
    final db = await DatabaseHelper.instance.database;
    final historyList = await db.query('playback_history');
    final favoritesList = await db.query('favorites');

    final Map<String, Map<String, dynamic>> historyMap = {
      for (var item in historyList) item['file_path'] as String: item
    };
    final Set<String> favoritePaths = {
      for (var item in favoritesList) item['file_path'] as String
    };

    // রুট ডিরেক্টরি নির্ধারণ (Internal Storage & SD Card)
    final List<Directory> roots = [];
    final internalStorage = Directory('/storage/emulated/0');
    if (await internalStorage.exists()) {
      roots.add(internalStorage);
    }

    final storageRoot = Directory('/storage');
    if (await storageRoot.exists()) {
      try {
        final List<FileSystemEntity> entities = storageRoot.listSync();
        for (var entity in entities) {
          if (entity is Directory && 
              entity.path != '/storage/emulated' && 
              entity.path != '/storage/self') {
            roots.add(entity); // SD Card যোগ করা
          }
        }
      } catch (_) {}
    }

    for (final root in roots) {
      await _scanDirectory(
        dir: root,
        videos: allVideos,
        audios: allAudios,
        historyMap: historyMap,
        favoritePaths: favoritePaths,
      );
    }

    // ফোল্ডার ক্যাটাগরি তৈরি
    final videoFolders = _generateFolders(allVideos, true);
    final audioFolders = _generateFolders(allAudios, false);

    return StorageScanResult(
      videos: allVideos,
      audios: allAudios,
      videoFolders: videoFolders,
      audioFolders: audioFolders,
    );
  }

  static Future<void> _scanDirectory({
    required Directory dir,
    required List<MediaItem> videos,
    required List<MediaItem> audios,
    required Map<String, Map<String, dynamic>> historyMap,
    required Set<String> favoritePaths,
  }) async {
    try {
      final List<FileSystemEntity> entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        final entityPath = entity.path;

        // হিডেন ফাইল ও সিস্টেম ডিরেক্টরি বাদ দেওয়া
        final name = p.basename(entityPath);
        if (name.startsWith('.')) continue;

        bool isExcluded = false;
        for (final excluded in MediaConstants.excludedFolders) {
          if (entityPath.contains(excluded)) {
            isExcluded = true;
            break;
          }
        }
        if (isExcluded) continue;

        if (entity is Directory) {
          await _scanDirectory(
            dir: entity,
            videos: videos,
            audios: audios,
            historyMap: historyMap,
            favoritePaths: favoritePaths,
          );
        } else if (entity is File) {
          final ext = p.extension(entityPath).toLowerCase().replaceAll('.', '');
          final isVideo = MediaConstants.supportedVideoExtensions.contains(ext);
          final isAudio = MediaConstants.supportedAudioExtensions.contains(ext);

          if (isVideo || isAudio) {
            final fileStat = entity.statSync();
            final parentDir = entity.parent;
            final historyData = historyMap[entityPath];

            final media = MediaItem(
              id: entityPath,
              path: entityPath,
              title: p.basenameWithoutExtension(entityPath),
              displayName: name,
              size: fileStat.size,
              durationMs: historyData != null ? (historyData['total_duration_ms'] as int? ?? 0) : 0,
              extension: ext,
              dateModified: fileStat.modified.millisecondsSinceEpoch,
              isVideo: isVideo,
              folderPath: parentDir.path,
              folderName: p.basename(parentDir.path),
              lastPositionMs: historyData != null ? (historyData['last_position_ms'] as int? ?? 0) : 0,
              watchedPercentage: historyData != null ? (historyData['watched_percentage'] as double? ?? 0.0) : 0.0,
              isFavorite: favoritePaths.contains(entityPath),
            );

            if (isVideo) {
              videos.add(media);
            } else {
              audios.add(media);
            }
          }
        }
      }
    } catch (_) {
      // অ্যান্ড্রয়েড সিস্টেম রেস্ট্রিক্টেড ফোল্ডারে রিড এরর আসলে বাইপাস করবে
    }
  }

  static List<MediaFolder> _generateFolders(List<MediaItem> mediaList, bool isVideo) {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in mediaList) {
      grouped.putIfAbsent(item.folderPath, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final totalSize = items.fold<int>(0, (sum, item) => sum + item.size);

      return MediaFolder(
        path: entry.key,
        name: items.first.folderName,
        mediaCount: items.length,
        videoCount: isVideo ? items.length : 0,
        audioCount: isVideo ? 0 : items.length,
        totalSizeBytes: totalSize,
        previewMedia: items.isNotEmpty ? items.first : null,
      );
    }).toList();
  }
}