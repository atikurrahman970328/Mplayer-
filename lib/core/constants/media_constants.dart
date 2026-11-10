class MediaConstants {
  // সমর্থিত ভিডিও এক্সটেনশন
  static const Set<String> supportedVideoExtensions = {
    'mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 
    'webm', '3gp', 'ts', 'm4v', 'mpg', 'mpeg', 'vob'
  };

  // সমর্থিত অডিও এক্সটেনশন
  static const Set<String> supportedAudioExtensions = {
    'mp3', 'aac', 'm4a', 'flac', 'wav', 
    'ogg', 'opus', 'wma', 'alac', 'mid', 'amr'
  };

  // সমর্থিত সাবটাইটেল এক্সটেনশন
  static const Set<String> supportedSubtitleExtensions = {
    'srt', 'ass', 'ssa', 'vtt', 'sub', 'idx', 'smi', 'txt'
  };

  // স্ক্যান করার সময় যে সিস্টেম ফোল্ডারগুলো বাদ দেওয়া হবে
  static const List<String> excludedFolders = [
    '/Android/data',
    '/Android/obb',
    '/.thumbnails',
    '/.secure_vault'
  ];
}