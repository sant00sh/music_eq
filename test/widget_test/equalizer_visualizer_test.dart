import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:music_eq/domain/entities/audio_file.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_state.dart';
import 'package:music_eq/presentation/widgets/equalizer_visualizer.dart';
import 'package:music_eq/presentation/widgets/loading_indicator.dart';
import 'package:waveform_extractor/model/waveform.dart';
import 'helpers/mocks.mocks.dart';

void main() {
  late MockAudioBloc mockAudioBloc;
  late MockAudioPlayer mockAudioPlayer;
  late MockWaveformExtractor mockWaveformExtractor;
  late StreamController<bool> playingStreamController;
  late StreamController<ProcessingState> processingStateStreamController;
  late StreamController<Duration> positionStreamController;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockAudioBloc = MockAudioBloc();
    mockAudioPlayer = MockAudioPlayer();
    mockWaveformExtractor = MockWaveformExtractor();

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

    when(mockWaveformExtractor.extractWaveform(any))
        .thenAnswer((_) async => Waveform(
              waveformData: List.generate(1000, (index) => 128),
              amplitudesForFirstSecond: List.generate(44100, (index) => 128),
              duration: const Duration(minutes: 3),
              source: 'test_path',
            ));
  });

  tearDown(() async {
    await playingStreamController.close();
    await processingStateStreamController.close();
    await positionStreamController.close();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        sliderTheme: const SliderThemeData(
          trackHeight: 4,
        ),
      ),
      home: Scaffold(
        body: Material(
          child: SizedBox(
            width: 800,
            height: 600,
            child: BlocProvider<AudioBloc>.value(
              value: mockAudioBloc,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('EqualizerVisualizer', () {
    testWidgets('should show loading indicator while extracting waveform',
        (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
        ),
      ));

      await tester.pump();
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should show visualization bars after loading', (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      when(mockWaveformExtractor.extractWaveform(any))
          .thenAnswer((_) async => Waveform(
                waveformData: List.generate(1000, (index) => 128),
                amplitudesForFirstSecond: List.generate(44100, (index) => 128),
                duration: const Duration(minutes: 3),
                source: 'test_path',
              ));

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
          barsCount: 30,
        ),
      ));

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should update progress bar when position changes',
        (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
        ),
      ));

      await tester.pump(const Duration(milliseconds: 50));
      positionStreamController.add(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('should handle slider value changes', (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      final seekCalls = <Duration>[];
      when(mockAudioPlayer.seek(any)).thenAnswer((invocation) {
        seekCalls.add(invocation.positionalArguments[0] as Duration);
        return Future.value();
      });

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
        ),
      ));

      await tester.pump(const Duration(milliseconds: 50));

      final Finder sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);

      clearInteractions(mockAudioPlayer);
      seekCalls.clear();

      await tester.drag(sliderFinder, const Offset(20.0, 0.0));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      verify(mockAudioPlayer.seek(any)).called(2);
      expect(seekCalls.length, 2);
      expect(seekCalls.every((duration) => duration.inMilliseconds > 0), true);
    });

    testWidgets('should start playing correctly', (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
        ),
      ));

      await tester.pump(const Duration(milliseconds: 50));

      playingStreamController.add(true);
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should handle completion state', (tester) async {
      const audioFile = AudioFile(url: 'test_url', title: 'test_title');
      when(mockAudioBloc.state).thenReturn(
        AudioLoaded(
          audioFile: audioFile,
          currentPosition: Duration.zero,
          barHeights: List.filled(30, 0.3),
        ),
      );

      await tester.pumpWidget(createTestWidget(
        EqualizerVisualizer(
          audioPlayer: mockAudioPlayer,
          audioFilePath: 'test_path',
        ),
      ));

      await tester.pump(const Duration(milliseconds: 50));

      processingStateStreamController.add(ProcessingState.completed);
      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('03:00'), findsOneWidget);
    });
  });
}
