import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VaultSecurityManager {
  // ৩২ বাইটের অফলাইন এনক্রিপশন কী
  static final _key = enc.Key.fromUtf8('my_32_bytes_super_secure_vault_k');
  static final _iv = enc.IV.fromLength(16);

  /// যেকোনো ভিডিও বা অডিও ফাইলকে AES-256 এ এনক্রিপ্ট করে সিকিউর ভল্টে সরানো
  static Future<File> encryptAndHideMedia(File originalFile) async {
    final encrypter = enc.Encrypter(enc.AES(_key));
    final bytes = await originalFile.readAsBytes();

    final encryptedData = encrypter.encryptBytes(bytes, iv: _iv);

    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/.secure_vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final newFilePath = p.join(vaultDir.path, '${p.basename(originalFile.path)}.enc');
    final encryptedFile = File(newFilePath);
    await encryptedFile.writeAsBytes(encryptedData.bytes);

    // মূল আন-এনক্রিপ্টেড ফাইলটি স্টোরেজ থেকে ডিলিট করা
    await originalFile.delete();

    return encryptedFile;
  }

  /// ফাইল আনহাইড করে পুনরায় আগের স্টোরেজ লোকেশনে ডিক্রিপ্ট করে ফিরিয়ে আনা
  static Future<File> decryptAndRestoreMedia(File encryptedFile, String originalPath) async {
    final encrypter = enc.Encrypter(enc.AES(_key));
    final encryptedBytes = await encryptedFile.readAsBytes();

    final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: _iv);

    final restoredFile = File(originalPath);
    await restoredFile.writeAsBytes(decryptedBytes);

    // এনক্রিপ্টেড ক্যাশ ফাইল ডিলিট
    if (await encryptedFile.exists()) {
      await encryptedFile.delete();
    }

    return restoredFile;
  }
}