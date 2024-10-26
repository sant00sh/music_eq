import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_eq/core/error/failures.dart';
import 'package:music_eq/domain/entities/audio_file.dart';
import 'package:music_eq/domain/usecases/get_audio_file.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_event.dart';
import 'package:music_eq/presentation/bloc/audio_state.dart';

import 'audio_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GetAudioFile>(), MockSpec<AudioPlayer>()])
void main() {
  late AudioBloc audioBloc;
  late MockGetAudioFile mockGetAudioFile;
  late MockAudioPlayer mockAudioPlayer;
  late AudioFile testAudioFile;
  late StreamController<Duration> positionController;

  setUp(() {
    mockGetAudioFile = MockGetAudioFile();
    mockAudioPlayer = MockAudioPlayer();
    testAudioFile = const AudioFile(url: 'test_url', title: 'test_title');

    positionController = StreamController<Duration>.broadcast();
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);

    audioBloc = AudioBloc(
      getAudioFile: mockGetAudioFile,
      audioPlayer: mockAudioPlayer,
    );
  });

  tearDown(() async {
    await positionController.close();
    await audioBloc.close();
  });

  group('AudioBloc', () {
    test('initial state is AudioInitial', () {
      expect(audioBloc.state, isA<AudioInitial>());
    });

    group('GetAudio Event', () {
      test('emits [AudioLoading, AudioLoaded] when GetAudio is successful',
          () async {
        when(mockGetAudioFile(any))
            .thenAnswer((_) async => Right(testAudioFile));
        when(mockAudioPlayer.setAudioSource(any, preload: true))
            .thenAnswer((_) async => Duration.zero);

        final future = expectLater(
          audioBloc.stream,
          emitsInOrder([
            isA<AudioLoading>(),
            isA<AudioLoaded>().having(
              (state) => state.audioFile,
              'audioFile',
              equals(testAudioFile),
            ),
          ]),
        );

        audioBloc.add(GetAudio());
        await future;
      });

      test('emits [AudioLoading, AudioError] when GetAudio fails', () async {
        when(mockGetAudioFile(any))
            .thenAnswer((_) async => Left(ServerFailure()));

        final future = expectLater(
          audioBloc.stream,
          emitsInOrder([
            isA<AudioLoading>(),
            isA<AudioError>(),
          ]),
        );

        audioBloc.add(GetAudio());
        await future;
      });
    });

    group('AudioPositionUpdated Event', () {
      test('updates current position when state is AudioLoaded', () async {
        when(mockGetAudioFile(any))
            .thenAnswer((_) async => Right(testAudioFile));
        when(mockAudioPlayer.setAudioSource(any, preload: true))
            .thenAnswer((_) async => Duration.zero);

        audioBloc.add(GetAudio());
        await expectLater(
          audioBloc.stream,
          emitsThrough(isA<AudioLoaded>()),
        );

        const newPosition = Duration(seconds: 10);

        final future = expectLater(
          audioBloc.stream,
          emits(
            isA<AudioLoaded>().having(
              (state) => state.currentPosition,
              'current position',
              equals(newPosition),
            ),
          ),
        );

        audioBloc.add(AudioPositionUpdated(newPosition));
        await future;
      });
    });

    group('SeekAudio Event', () {
      test('seeks to new position and updates state', () async {
        when(mockGetAudioFile(any))
            .thenAnswer((_) async => Right(testAudioFile));
        when(mockAudioPlayer.setAudioSource(any, preload: true))
            .thenAnswer((_) async => Duration.zero);
        when(mockAudioPlayer.seek(any)).thenAnswer((_) async {});

        audioBloc.add(GetAudio());
        await expectLater(
          audioBloc.stream,
          emitsThrough(isA<AudioLoaded>()),
        );

        const newPosition = Duration(seconds: 15);

        final future = expectLater(
          audioBloc.stream,
          emits(
            isA<AudioLoaded>().having(
              (state) => state.currentPosition,
              'current position',
              equals(newPosition),
            ),
          ),
        );

        audioBloc.add(SeekAudio(newPosition));
        await future;

        verify(mockAudioPlayer.seek(newPosition)).called(1);
      });
    });

    group('UpdateVisualizerBars Event', () {
      test('updates bar heights when state is AudioLoaded', () async {
        when(mockGetAudioFile(any))
            .thenAnswer((_) async => Right(testAudioFile));
        when(mockAudioPlayer.setAudioSource(any, preload: true))
            .thenAnswer((_) async => Duration.zero);

        audioBloc.add(GetAudio());
        await expectLater(
          audioBloc.stream,
          emitsThrough(isA<AudioLoaded>()),
        );

        final newBarHeights = List.filled(30, 0.5);

        final future = expectLater(
          audioBloc.stream,
          emits(
            isA<AudioLoaded>().having(
              (state) => state.barHeights,
              'bar heights',
              equals(newBarHeights),
            ),
          ),
        );

        audioBloc.add(UpdateVisualizerBars(newBarHeights));
        await future;
      });
    });

    test('disposes AudioPlayer when bloc is closed', () async {
      when(mockAudioPlayer.dispose()).thenAnswer((_) async {});

      await audioBloc.close();

      verify(mockAudioPlayer.dispose()).called(1);
    });
  });
}
