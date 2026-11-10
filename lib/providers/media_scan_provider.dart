import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/media_model.dart';
import '../../models/folder_model.dart';
import '../services/storage_scanner.dart';
import '../../database/db_helper.dart';

class MediaState {
  final bool isLoading;
  final bool permissionGranted;
  final List<MediaItem> allVideos;
  final List<MediaItem> allAudios;
  final List<MediaFolder> videoFolders;
  final List<MediaFolder> audioFolders;
  final String statusMessage;

  MediaState({
    required this.isLoading,
    required this.permissionGranted,
    required this.allVideos,
    required this.allAudios,
    required this.videoFolders,
    required this.audioFolders,
    required this.statusMessage,
  });

  factory MediaState.initial() => MediaState(
    isLoading: true,
    permissionGranted: false,
    allVideos: [],
    allAudios: [],
    videoFolders: [],
    audioFolders: [],
    statusMessage: 'স্টোরেজ পারমিশন যাচাই করা হচ্ছে...',
  );

  MediaState copyWith({
    bool? isLoading,
    bool? permissionGranted,
    List<MediaItem>? allVideos,
    List<MediaItem>? allAudios,
    List<MediaFolder>? videoFolders,
    List<MediaFolder>? audioFolders,
    String? statusMessage,
  }) {
    return MediaState(
      isLoading: isLoading ?? this.isLoading,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      allVideos: allVideos ?? this.allVideos,
      allAudios: allAudios ?? this.allAudios,
      videoFolders: videoFolders ?? this.videoFolders,
      audioFolders: audioFolders ?? this.audioFolders,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class MediaNotifier extends StateNotifier<MediaState> {
  MediaNotifier() : super(MediaState.initial());

  Future<void> initAndScan() async {
    state = state.copyWith(isLoading: true, statusMessage: 'পারমিশন যাচাই করা হচ্ছে...');
    final hasPermission = await StorageScanner.requestStoragePermissions();

    if (!hasPermission) {
      state = state.copyWith(
        isLoading: false,
        permissionGranted: false,
        statusMessage: 'স্টোরেজ অ্যাক্সেস পারমিশন প্রয়োজন!',
      );
      return;
    }

    state = state.copyWith(
      permissionGranted: true,
      statusMessage: 'অফলাইন মিডিয়া ফাইল স্ক্যান করা হচ্ছে...',
    );

    final result = await StorageScanner.scanDeviceStorage();

    state = state.copyWith(
      isLoading: false,
      allVideos: result.videos,
      allAudios: result.audios,
      videoFolders: result.videoFolders,
      audioFolders: result.audioFolders,
      statusMessage: 'স্ক্যান সফল হয়েছে',
    );
  }

  Future<void> toggleFavorite(MediaItem item) async {
    final db = await DatabaseHelper.instance.database;
    final newFavoriteStatus = !item.isFavorite;

    if (newFavoriteStatus) {
      await db.insert('favorites', {
        'file_path': item.path,
        'media_type': item.isVideo ? 'video' : 'audio',
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.delete(
        'favorites',
        where: 'file_path = ?',
        whereArgs: [item.path],
      );
    }

    // লোকাল স্টেট আপডেট
    if (item.isVideo) {
      final updatedVideos = state.allVideos.map((v) {
        return v.path == item.path ? v.copyWith(isFavorite: newFavoriteStatus) : v;
      }).toList();
      state = state.copyWith(allVideos: updatedVideos);
    } else {
      final updatedAudios = state.allAudios.map((a) {
        return a.path == item.path ? a.copyWith(isFavorite: newFavoriteStatus) : a;
      }).toList();
      state = state.copyWith(allAudios: updatedAudios);
    }
  }
}

final mediaProvider = StateNotifierProvider<MediaNotifier, MediaState>((ref) {
  return MediaNotifier();
});