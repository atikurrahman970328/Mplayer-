import 'media_model.dart';

class MediaFolder {
  final String path;
  final String name;
  final int mediaCount;
  final int videoCount;
  final int audioCount;
  final int totalSizeBytes;
  final MediaItem? previewMedia;

  MediaFolder({
    required this.path,
    required this.name,
    required this.mediaCount,
    required this.videoCount,
    required this.audioCount,
    required this.totalSizeBytes,
    this.previewMedia,
  });

  String get formattedTotalSize {
    if (totalSizeBytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double dSize = totalSizeBytes.toDouble();
    while (dSize >= 1024 && i < suffixes.length - 1) {
      dSize /= 1024;
      i++;
    }
    return '${dSize.toStringAsFixed(1)} ${suffixes[i]}';
  }
}