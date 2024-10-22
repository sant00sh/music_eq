import 'package:music_eq/domain/entities/audio_file.dart';

class AudioFileModel extends AudioFile {
  const AudioFileModel({required super.url, required super.title});

  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    return AudioFileModel(
      url: json['url'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
    };
  }
}
