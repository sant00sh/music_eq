import 'package:dartz/dartz.dart';
import 'package:music_eq/core/error/failures.dart';
import 'package:music_eq/domain/entities/audio_file.dart';

abstract class AudioRepository {
  Future<Either<Failure, AudioFile>> getAudioFile();
}