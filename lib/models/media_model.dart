class MediaItem {
  final String id;
  final String path;
  final String title;
  final String displayName;
  final int size; // Bytes
  final int durationMs;
  final String resolution;
  final String extension;
  final int dateModified;
  final bool isVideo;
  final String folderPath;
  final String folderName;
  final int lastPositionMs;
  final double watchedPercentage;
  final bool isFavorite;

  MediaItem({
    required this.id,
    required this.path,
    required this.title,
    required this.displayName,
    required this.size,
    required this.durationMs,
    this.resolution = 'Unknown',
    required this.extension,
    required this.dateModified,
    required this.isVideo,
    required this.folderPath,
    required this.folderName,
    this.lastPositionMs = 0,
    this.watchedPercentage = 0.0,
    this.isFavorite = false,
  });

  String get formattedDuration {
    if (durationMs <= 0) return "--:--";
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedSize {
    if (size <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double dSize = size.toDouble();
    while (dSize >= 1024 && i < suffixes.length - 1) {
      dSize /= 1024;
      i++;
    }
    return '${dSize.toStringAsFixed(1)} ${suffixes[i]}';
  }

  MediaItem copyWith({
    int? lastPositionMs,
    double? watchedPercentage,
    bool? isFavorite,
  }) {
    return MediaItem(
      id: id,
      path: path,
      title: title,
      displayName: displayName,
      size: size,
      durationMs: durationMs,
      resolution: resolution,
      extension: extension,
      dateModified: dateModified,
      isVideo: isVideo,
      folderPath: folderPath,
      folderName: folderName,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      watchedPercentage: watchedPercentage ?? this.watchedPercentage,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}