import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AudioDownloader {
  final http.Client client;
  late Directory cacheDirectory;
  static const String cacheFolderName = 'audio_cache';

  AudioDownloader({required this.client});

  Future<void> initializeCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    cacheDirectory = Directory(path.join(tempDir.path, cacheFolderName));

    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
  }

  Future<String> downloadAndGetPath(String url) async {
    try {
      final filename = path.basename(url);
      final filePath = path.join(cacheDirectory.path, filename);

      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download audio file');
      }

      await file.writeAsBytes(response.bodyBytes);
      return filePath;

    } catch (e) {
      throw Exception('Error downloading audio file: $e');
    }
  }

  Future<void> clearCache() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
      await cacheDirectory.create();
    }
  }
}