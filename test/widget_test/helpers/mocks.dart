import 'package:mockito/annotations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:waveform_extractor/waveform_extractor.dart';

@GenerateNiceMocks([
  MockSpec<AudioBloc>(),
  MockSpec<AudioPlayer>(),
  MockSpec<WaveformExtractor>(),
])
void main() {}