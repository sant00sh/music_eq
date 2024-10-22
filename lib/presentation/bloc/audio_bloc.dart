import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_eq/core/usecase/usecase.dart';
import 'package:music_eq/domain/usecases/get_audio_file.dart';
import 'audio_event.dart';
import 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final GetAudioFile getAudioFile;
  final AudioPlayer audioPlayer;
  static const int barsCount = 30;

  AudioBloc({required this.getAudioFile, required this.audioPlayer})
      : super(AudioInitial()) {
    on<GetAudio>(_onGetAudio);
    on<AudioPositionUpdated>(_onAudioPositionUpdated);
    on<SeekAudio>(_onSeekAudio);
    on<UpdateVisualizerBars>(_onUpdateVisualizerBars);
    on<ResetVisualizerBars>(_onResetVisualizerBars);

    audioPlayer.positionStream.listen((position) {
      add(AudioPositionUpdated(position));
    });
  }

  Future<void> _onGetAudio(GetAudio event, Emitter<AudioState> emit) async {
    emit(AudioLoading());
    final failureOrAudio = await getAudioFile(NoParams());

    await failureOrAudio.fold(
      (failure) async {
        emit(AudioError(message: 'Error loading audio'));
      },
      (audioFile) async {
        try {
          final audioSource = AudioSource.file(audioFile.url);
          await audioPlayer.setAudioSource(audioSource, preload: true);
          emit(AudioLoaded(
            audioFile: audioFile,
            barHeights: List.filled(barsCount, 0.3),
          ));
        } catch (e) {
          emit(AudioError(message: 'Error preparing audio: $e'));
        }
      },
    );
  }

  void _onAudioPositionUpdated(
      AudioPositionUpdated event, Emitter<AudioState> emit) {
    if (state is AudioLoaded) {
      final loadedState = state as AudioLoaded;
      emit(loadedState.copyWith(currentPosition: event.position));
    }
  }

  Future<void> _onSeekAudio(SeekAudio event, Emitter<AudioState> emit) async {
    await audioPlayer.seek(event.newPosition);
    if (state is AudioLoaded) {
      final loadedState = state as AudioLoaded;
      emit(loadedState.copyWith(currentPosition: event.newPosition));
    }
  }

  void _onUpdateVisualizerBars(
      UpdateVisualizerBars event, Emitter<AudioState> emit) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(barHeights: event.barHeights));
    }
  }

  void _onResetVisualizerBars(
      ResetVisualizerBars event, Emitter<AudioState> emit) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(
        barHeights: currentState.barHeights,
      ));
    }
  }

  @override
  Future<void> close() async {
    await audioPlayer.dispose();
    return super.close();
  }
}
