import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class PlaylistModel {
  final int id;
  final String name;
  final int createdAt;
  final int itemCount;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.itemCount = 0,
  });
}

class PlaylistRepository {
  static Future<int> createPlaylist(String name) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('playlists', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<PlaylistModel>> getPlaylists() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.id, p.name, p.created_at, COUNT(pi.id) as item_count 
      FROM playlists p 
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id 
      GROUP BY p.id 
      ORDER BY p.created_at DESC
    ''');

    return maps.map((m) => PlaylistModel(
      id: m['id'] as int,
      name: m['name'] as String,
      createdAt: m['created_at'] as int,
      itemCount: m['item_count'] as int,
    )).toList();
  }

  static Future<void> deletePlaylist(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> addMediaToPlaylist(int playlistId, String filePath) async {
    final db = await DatabaseHelper.instance.database;
    final countList = await db.rawQuery('SELECT COUNT(*) as count FROM playlist_items WHERE playlist_id = ?', [playlistId]);
    final int nextOrder = Sqflite.firstIntValue(countList) ?? 0;

    await db.insert('playlist_items', {
      'playlist_id': playlistId,
      'file_path': filePath,
      'order_index': nextOrder,
    });
  }

  static Future<List<String>> getPlaylistFilePaths(int playlistId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlist_items',
      columns: ['file_path'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'order_index ASC',
    );
    return maps.map((m) => m['file_path'] as String).toList();
  }

  static Future<void> removePlaylistItem(int playlistId, String filePath) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND file_path = ?',
      whereArgs: [playlistId, filePath],
    );
  }
}