import 'package:http/http.dart' as http;
import 'package:music_eq/core/constants/apis.dart';
import 'package:music_eq/data/datasources/audio_downloader.dart';
import 'package:music_eq/data/models/audio_file_model.dart';

abstract class AudioRemoteDataSource {
  Future<AudioFileModel> fetchAudioFile();
}

class AudioRemoteDataSourceImpl implements AudioRemoteDataSource {
  final http.Client client;
  final AudioDownloader audioDownloader;

  AudioRemoteDataSourceImpl({
    required this.client,
    required this.audioDownloader,
  });

  @override
  Future<AudioFileModel> fetchAudioFile() async {
    try {
      final response = await client.get(Uri.parse(APIs.musicUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to verify audio file');
      }

      final localPath = await audioDownloader.downloadAndGetPath(APIs.musicUrl);

      return AudioFileModel(
        url: localPath,
        title: 'Background Music',
      );
    } catch (e) {
      throw Exception('Failed to load audio file: $e');
    }
  }
}