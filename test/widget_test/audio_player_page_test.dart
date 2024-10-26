import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_eq/core/constants/index.dart';
import 'package:music_eq/domain/entities/audio_file.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_event.dart';
import 'package:music_eq/presentation/bloc/audio_state.dart';
import 'package:music_eq/presentation/pages/audio_player_page.dart';
import 'package:music_eq/presentation/widgets/equalizer_visualizer.dart';
import 'package:music_eq/presentation/widgets/loading_indicator.dart';

import 'helpers/mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AudioBloc>(),
  MockSpec<AudioPlayer>(),
])
void main() {
  late MockAudioBloc mockAudioBloc;
  late MockAudioPlayer mockAudioPlayer;
  late StreamController<bool> playingStreamController;
  late StreamController<ProcessingState> processingStateStreamController;
  late StreamController<Duration> positionStreamController;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockAudioBloc = MockAudioBloc();
    mockAudioPlayer = MockAudioPlayer();
    playingStreamController = StreamController<bool>.broadcast();
    processingStateStreamController =
        StreamController<ProcessingState>.broadcast();
    positionStreamController = StreamController<Duration>.broadcast();

    when(mockAudioPlayer.playingStream)
        .thenAnswer((_) => playingStreamController.stream);
    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateStreamController.stream);
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionStreamController.stream);
    when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 3));
    when(mockAudioBloc.audioPlayer).thenReturn(mockAudioPlayer);
  });

  tearDown(() async {
    await playingStreamController.close();
    await processingStateStreamController.close();
    await positionStreamController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<AudioBloc>.value(
          value: mockAudioBloc,
          child: const AudioPlayerPage(),
        ),
      ),
    );
  }

  group('AudioPlayerPage', () {
    testWidgets('should show initial state message', (tester) async {
      when(mockAudioBloc.state).thenReturn(AudioInitial());
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text(Labels.pressToPlay), findsOneWidget);
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      when(mockAudioBloc.state).thenReturn(AudioLoading());
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.text(Labels.pressToPlay), findsNothing);
    });

    testWidgets('should show error state with retry button', (tester) async {
      when(mockAudioBloc.state).thenReturn(AudioError(message: 'Test error'));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Error: Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      clearInteractions(mockAudioBloc);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(mockAudioBloc.add(GetAudio())).called(1);
    });

    testWidgets('should show loaded state with controls', (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(EqualizerVisualizer), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('should toggle play/pause when play button is pressed',
        (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );
      when(mockAudioPlayer.playing).thenReturn(false);
      playingStreamController.add(false);
      processingStateStreamController.add(ProcessingState.ready);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();
      verify(mockAudioPlayer.play()).called(1);

      when(mockAudioPlayer.playing).thenReturn(true);
      playingStreamController.add(true);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.pause_circle_filled));
      await tester.pump();
      verify(mockAudioPlayer.pause()).called(1);
    });
  });
}
