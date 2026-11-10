import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_colors.dart';
import '../../core/utils/security_helper.dart';
import '../../database/db_helper.dart';
import '../../models/media_model.dart';
import '../../providers/media_scan_provider.dart';
import 'auth_pin_sheet.dart';

class PrivateFolderPage extends ConsumerStatefulWidget {
  const PrivateFolderPage({super.key});

  @override
  ConsumerState<PrivateFolderPage> createState() => _PrivateFolderPageState();
}

class _PrivateFolderPageState extends ConsumerState<PrivateFolderPage> {
  bool _isAuthenticated = false;
  List<Map<String, dynamic>> _vaultMedia = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showAuthModal());
  }

  void _showAuthModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AuthPinSheet(
        onAuthenticated: () {
          Navigator.pop(context);
          setState(() => _isAuthenticated = true);
          _loadVaultItems();
        },
      ),
    );
  }

  Future<void> _loadVaultItems() async {
    final db = await DatabaseHelper.instance.database;
    final list = await db.query('private_vault', orderBy: 'added_at DESC');
    setState(() => _vaultMedia = list);
  }

  Future<void> _restoreFile(Map<String, dynamic> item) async {
    final encPath = item['vault_path'] as String;
    final origPath = item['original_path'] as String;

    await VaultSecurityManager.decryptAndRestoreMedia(File(encPath), origPath);

    final db = await DatabaseHelper.instance.database;
    await db.delete('private_vault', where: 'id = ?', whereArgs: [item['id']]);

    ref.read(mediaProvider.notifier).initAndScan();
    _loadVaultItems();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ফাইলটি মূল ফোল্ডারে সফলভাবে রিস্টোর হয়েছে।")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text("প্রাইভেট ভল্ট (Secure Vault)")),
        body: const Center(child: Text("লক আনলক করুন...", style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("প্রাইভেট ভল্ট (Secure Vault)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_rounded, color: Colors.amberAccent),
            tooltip: "Lock Vault",
            onPressed: () => setState(() {
              _isAuthenticated = false;
              _showAuthModal();
            }),
          ),
        ],
      ),
      body: _vaultMedia.isEmpty
          ? const Center(
              child: Text("কোনো গোপন মিডিয়া ফাইল নেই\n(+) বাটন চেপে ফাইল লুকিয়ে রাখুন",
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              itemCount: _vaultMedia.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final item = _vaultMedia[index];
                return ListTile(
                  leading: const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 30),
                  title: Text(item['file_name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text(
                    "আকার: ${(item['file_size'] / (1024 * 1024)).toStringAsFixed(1)} MB",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'restore') _restoreFile(item);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'restore', child: Text("আনহাইড ও রিস্টোর করুন")),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
        label: const Text("লুকিয়ে রাখুন", style: TextStyle(color: Colors.white)),
        onPressed: _showHideMediaPicker,
      ),
    );
  }

  void _showHideMediaPicker() {
    final mediaState = ref.read(mediaProvider);
    final allMedia = [...mediaState.allVideos, ...mediaState.allAudios];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => ListView.builder(
        itemCount: allMedia.length,
        itemBuilder: (c, i) {
          final m = allMedia[i];
          return ListTile(
            leading: Icon(m.isVideo ? Icons.movie_outlined : Icons.music_note_rounded, color: AppColors.primary),
            title: Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () async {
              Navigator.pop(ctx);
              final encryptedFile = await VaultSecurityManager.encryptAndHideMedia(File(m.path));
              final db = await DatabaseHelper.instance.database;
              await db.insert('private_vault', {
                'original_path': m.path,
                'vault_path': encryptedFile.path,
                'media_type': m.isVideo ? 'video' : 'audio',
                'file_name': p.basename(m.path),
                'file_size': m.size,
                'added_at': DateTime.now().millisecondsSinceEpoch,
              });

              ref.read(mediaProvider.notifier).initAndScan();
              _loadVaultItems();
            },
          );
        },
      ),
    );
  }
}