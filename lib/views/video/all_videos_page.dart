import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';

enum SortOption { nameAsc, nameDesc, dateNewest, dateOldest, sizeLargest, sizeSmallest }

class AllVideosPage extends ConsumerStatefulWidget {
  const AllVideosPage({super.key});

  @override
  ConsumerState<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends ConsumerState<AllVideosPage> {
  bool _isGridView = false;
  SortOption _sortOption = SortOption.dateNewest;
  String _selectedFormat = 'ALL';
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    var videoList = List<MediaItem>.from(mediaState.allVideos);

    // ফরম্যাট ফিল্টারিং
    if (_selectedFormat != 'ALL') {
      videoList = videoList.where((v) => v.extension.toUpperCase() == _selectedFormat).toList();
    }

    // শর্টিং
    videoList.sort((a, b) {
      switch (_sortOption) {
        case SortOption.nameAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.nameDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case SortOption.dateNewest:
          return b.dateModified.compareTo(a.dateModified);
        case SortOption.dateOldest:
          return a.dateModified.compareTo(b.dateModified);
        case SortOption.sizeLargest:
          return b.size.compareTo(a.size);
        case SortOption.sizeSmallest:
          return a.size.compareTo(b.size);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isSelectionMode ? _buildSelectionAppBar(videoList) : null,
      body: Column(
        children: [
          // ফরম্যাট ফিল্টার চিপস এবং ভিউ টগল বার
          _buildFilterAndSortBar(mediaState.allVideos),

          // ভিডিও তালিকা বা গ্রিড
          Expanded(
            child: videoList.isEmpty
                ? const Center(
                    child: Text("কোনো ভিডিও পাওয়া যায়নি", style: TextStyle(color: AppColors.textSecondary)),
                  )
                : _isGridView
                    ? _buildGridView(videoList)
                    : _buildListView(videoList),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(List<MediaItem> allCurrent) {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(() {
          _isSelectionMode = false;
          _selectedItems.clear();
        }),
      ),
      title: Text("${_selectedItems.length} টি নির্বাচিত"),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all_rounded),
          tooltip: "সব নির্বাচন করুন",
          onPressed: () {
            setState(() {
              if (_selectedItems.length == allCurrent.length) {
                _selectedItems.clear();
              } else {
                _selectedItems.addAll(allCurrent.map((e) => e.path));
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterAndSortBar(List<MediaItem> rawList) {
    final formats = ['ALL', ...rawList.map((e) => e.extension.toUpperCase()).toSet()];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // ফরম্যাট ড্রপডাউন বা ফিল্টার লিস্ট
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: formats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final fmt = formats[i];
                      final isSelected = _selectedFormat == fmt;
                      return ChoiceChip(
                        label: Text(fmt),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        onSelected: (val) => setState(() => _selectedFormat = fmt),
                      );
                    },
                  ),
                ),
              ),
              // শর্টিং পপআপ
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
                tooltip: "Sort Videos",
                onSelected: (opt) => setState(() => _sortOption = opt),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: SortOption.dateNewest, child: Text("নতুন প্রথম (Newest)")),
                  PopupMenuItem(value: SortOption.dateOldest, child: Text("পুরানো প্রথম (Oldest)")),
                  PopupMenuItem(value: SortOption.nameAsc, child: Text("নাম (A to Z)")),
                  PopupMenuItem(value: SortOption.nameDesc, child: Text("নাম (Z to A)")),
                  PopupMenuItem(value: SortOption.sizeLargest, child: Text("আকার (বড় থেকে ছোট)")),
                  PopupMenuItem(value: SortOption.sizeSmallest, child: Text("আকার (ছোট থেকে বড়)")),
                ],
              ),
              // গ্রিড / লিস্ট টগল
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<MediaItem> list) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedItems.contains(item.path);

        return ListTile(
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedItems.add(item.path);
            });
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedItems.remove(item.path);
                  if (_selectedItems.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedItems.add(item.path);
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playing "${item.title}" (ধাপ ৩ এ প্লেয়ারে লোড হবে)')),
              );
            }
          },
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie_outlined, color: AppColors.textSecondary),
              ),
              if (item.watchedPercentage > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: item.watchedPercentage / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 3,
                  ),
                ),
              if (_isSelectionMode)
                Positioned(
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
            ],
          ),
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Text(item.formattedDuration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Text("  •  ", style: TextStyle(color: AppColors.textSecondary)),
              Text(item.formattedSize, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Text("  •  ", style: TextStyle(color: AppColors.textSecondary)),
              Text(item.folderName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          trailing: _isSelectionMode
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  onSelected: (val) => _handleMenuAction(val, item),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "play", child: Text("চালান (Play)")),
                    PopupMenuItem(
                      value: "fav",
                      child: Text(item.isFavorite ? "পছন্দ থেকে সরান" : "পছন্দে যোগ করুন"),
                    ),
                    const PopupMenuItem(value: "rename", child: Text("নাম পরিবর্তন (Rename)")),
                    const PopupMenuItem(value: "delete", child: Text("মুছে ফেলুন (Delete)")),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildGridView(List<MediaItem> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedItems.contains(item.path);

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedItems.remove(item.path);
                  if (_selectedItems.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedItems.add(item.path);
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playing "${item.title}"')),
              );
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedItems.add(item.path);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                        ),
                        child: const Center(
                          child: Icon(Icons.movie_creation_outlined, size: 36, color: AppColors.textSecondary),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.formattedDuration,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item.formattedSize} • ${item.extension.toUpperCase()}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      color: AppColors.surface,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            tooltip: "Delete Selected",
            onPressed: _deleteSelectedItems,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: AppColors.activeGreen),
            tooltip: "Favorite Selected",
            onPressed: () {
              // ফেভারিট টগল
              final mediaList = ref.read(mediaProvider).allVideos;
              for (final path in _selectedItems) {
                final item = mediaList.firstWhere((e) => e.path == path);
                ref.read(mediaProvider.notifier).toggleFavorite(item);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedItems.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, MediaItem item) {
    if (action == "fav") {
      ref.read(mediaProvider.notifier).toggleFavorite(item);
    } else if (action == "delete") {
      _confirmDeleteSingle(item);
    } else if (action == "rename") {
      _showRenameDialog(item);
    }
  }

  void _confirmDeleteSingle(MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ভিডিও মুছে ফেলবেন?"),
        content: Text("আপনি কি নিশ্চিতভাবে \"${item.displayName}\" ডিভাইস থেকে চিরতরে মুছে ফেলতে চান?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              try {
                final file = File(item.path);
                if (file.existsSync()) file.deleteSync();
                ref.read(mediaProvider.notifier).initAndScan();
              } catch (_) {}
            },
            child: const Text("মুছুন", style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedItems() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("নির্বাচিত ফাইলগুলো মুছবেন?"),
        content: Text("${_selectedItems.length} টি ফাইল স্টোরেজ থেকে ডিলিট করা হবে।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (var path in _selectedItems) {
                try {
                  final f = File(path);
                  if (f.existsSync()) f.deleteSync();
                } catch (_) {}
              }
              setState(() {
                _isSelectionMode = false;
                _selectedItems.clear();
              });
              ref.read(mediaProvider.notifier).initAndScan();
            },
            child: const Text("মুছুন", style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(MediaItem item) {
    final controller = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("নাম পরিবর্তন"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "নতুন নাম লিখুন"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final file = File(item.path);
                final newPath = "${item.folderPath}/$newName.${item.extension}";
                try {
                  file.renameSync(newPath);
                  ref.read(mediaProvider.notifier).initAndScan();
                } catch (_) {}
              }
            },
            child: const Text("সংরক্ষণ", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}