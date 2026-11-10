import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_colors.dart';
import '../../providers/media_scan_provider.dart';

class FileManagerPage extends ConsumerStatefulWidget {
  const FileManagerPage({super.key});

  @override
  ConsumerState<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends ConsumerState<FileManagerPage> {
  late Directory _currentDir;
  List<FileSystemEntity> _entities = [];

  @override
  void initState() {
    super.initState();
    _currentDir = Directory('/storage/emulated/0');
    _loadDirectory(_currentDir);
  }

  void _loadDirectory(Directory dir) {
    try {
      if (dir.existsSync()) {
        final list = dir.listSync(followLinks: false);
        // ফোল্ডার আগে এবং পরে ফাইল আকারে সাজানো
        list.sort((a, b) {
          final isADir = a is Directory;
          final isBDir = b is Directory;
          if (isADir && !isBDir) return -1;
          if (!isADir && isBDir) return 1;
          return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
        });
        setState(() {
          _currentDir = dir;
          _entities = list;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ফোল্ডার অ্যাক্সেস করা সম্ভব নয়!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentDir.path != '/storage/emulated/0') {
          _loadDirectory(_currentDir.parent);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            p.basename(_currentDir.path).isEmpty ? "Storage" : p.basename(_currentDir.path),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: "New Folder",
              onPressed: _createNewFolderDialog,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // পাথ ব্রেডক্রাম্ব
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Text(
                _currentDir.path,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: _entities.isEmpty
                  ? const Center(
                      child: Text("ফোল্ডারটি ফাঁকা", style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      itemCount: _entities.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                      itemBuilder: (context, index) {
                        final entity = _entities[index];
                        final isDir = entity is Directory;
                        final name = p.basename(entity.path);

                        return ListTile(
                          leading: Icon(
                            isDir ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
                            color: isDir ? Colors.amberAccent : AppColors.primary,
                            size: 30,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                          onTap: () {
                            if (isDir) {
                              _loadDirectory(Directory(entity.path));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected file: $name')),
                              );
                            }
                          },
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                            onSelected: (action) => _handleAction(action, entity),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: "delete", child: Text("Delete")),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, FileSystemEntity entity) {
    if (action == "delete") {
      try {
        if (entity is Directory) {
          entity.deleteSync(recursive: true);
        } else {
          entity.deleteSync();
        }
        _loadDirectory(_currentDir);
        ref.read(mediaProvider.notifier).initAndScan();
      } catch (_) {}
    }
  }

  void _createNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("নতুন ফোল্ডার তৈরি করুন"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "ফোল্ডারের নাম"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newDir = Directory("${_currentDir.path}/$name");
                if (!newDir.existsSync()) {
                  newDir.createSync();
                  _loadDirectory(_currentDir);
                }
              }
            },
            child: const Text("তৈরি করুন", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}