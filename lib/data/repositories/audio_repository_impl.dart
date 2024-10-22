import 'package:dartz/dartz.dart';
import 'package:music_eq/core/error/failures.dart';
import 'package:music_eq/data/datasources/audio_remote_data_source.dart';
import 'package:music_eq/domain/entities/audio_file.dart';
import 'package:music_eq/domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioRemoteDataSource remoteDataSource;

  AudioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AudioFile>> getAudioFile() async {
    try {
      final audioFile = await remoteDataSource.fetchAudioFile();
      return Right(audioFile);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}