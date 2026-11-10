import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filterType = 'ALL'; // ALL, VIDEO, AUDIO

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);

    List<MediaItem> searchResults = [];
    if (_query.isNotEmpty) {
      final combined = [...mediaState.allVideos, ...mediaState.allAudios];
      searchResults = combined.where((item) {
        final matchesQuery = item.title.toLowerCase().contains(_query.toLowerCase()) ||
            item.folderName.toLowerCase().contains(_query.toLowerCase());

        if (_filterType == 'VIDEO') {
          return matchesQuery && item.isVideo;
        } else if (_filterType == 'AUDIO') {
          return matchesQuery && !item.isVideo;
        }
        return matchesQuery;
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "অফলাইন ভিডিও বা গান খুঁজুন...",
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
      ),
      body: Column(
        children: [
          // ফিল্টার চিপস
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildFilterChip("ALL", "সব"),
                const SizedBox(width: 8),
                _buildFilterChip("VIDEO", "ভিডিও"),
                const SizedBox(width: 8),
                _buildFilterChip("AUDIO", "অডিও/গান"),
              ],
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Text("খুঁজতে ফাইলের নাম লিখুন", style: TextStyle(color: AppColors.textSecondary)),
                  )
                : searchResults.isEmpty
                    ? const Center(
                        child: Text("কোনো মিডিয়া ফাইল পাওয়া যায়নি", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return ListTile(
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.isVideo ? Icons.movie_outlined : Icons.music_note_rounded,
                                color: item.isVideo ? AppColors.primary : AppColors.activeGreen,
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "${item.folderName} • ${item.formattedSize}",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            trailing: Text(
                              item.extension.toUpperCase(),
                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected: "${item.title}"')),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _filterType = type),
    );
  }
}