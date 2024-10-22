import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:music_eq/data/datasources/audio_downloader.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';

import 'data/datasources/audio_remote_data_source.dart';
import 'data/repositories/audio_repository_impl.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/usecases/get_audio_file.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => AudioBloc(
    getAudioFile: sl(),
    audioPlayer: sl(),
  ));

  sl.registerLazySingleton(() => GetAudioFile(sl()));

  sl.registerLazySingleton<AudioRepository>(
        () => AudioRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => AudioDownloader(client: sl()));

  sl.registerLazySingleton<AudioRemoteDataSource>(
        () => AudioRemoteDataSourceImpl(
      client: sl(),
      audioDownloader: sl(),
    ),
  );

  sl.registerLazySingleton(() => http.Client());

  sl.registerLazySingleton(() => AudioPlayer());

  final audioDownloader = sl<AudioDownloader>();
  await audioDownloader.initializeCacheDirectory();
}