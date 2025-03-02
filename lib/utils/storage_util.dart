import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageUtil {
  static final StorageUtil _instance = StorageUtil._internal();
  factory StorageUtil() => _instance;
  StorageUtil._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> saveFile(String sourcePath, String type) async {
    final String localPath = await _localPath;
    final String fileName = '${const Uuid().v4()}${path.extension(sourcePath)}';
    final String targetPath = path.join(localPath, type, fileName);

    // Create type directory if it doesn't exist
    final typeDir = Directory(path.join(localPath, type));
    if (!await typeDir.exists()) {
      await typeDir.create(recursive: true);
    }

    // Copy file to local storage
    final File sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);

    return targetPath;
  }

  Future<bool> fileExists(String filePath) async {
    if (filePath.isEmpty) return false;
    return await File(filePath).exists();
  }

  Future<void> deleteFile(String filePath) async {
    if (await fileExists(filePath)) {
      await File(filePath).delete();
    }
  }
}
