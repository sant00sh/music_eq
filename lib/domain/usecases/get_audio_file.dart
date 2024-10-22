import 'package:dartz/dartz.dart';
import 'package:music_eq/core/error/failures.dart';
import 'package:music_eq/core/usecase/usecase.dart';
import 'package:music_eq/domain/entities/audio_file.dart';
import 'package:music_eq/domain/repositories/audio_repository.dart';

class GetAudioFile implements UseCase<AudioFile, NoParams> {
  final AudioRepository repository;

  GetAudioFile(this.repository);

  @override
  Future<Either<Failure, AudioFile>> call(NoParams params) async {
    return await repository.getAudioFile();
  }
}
