import 'package:equatable/equatable.dart';

abstract class AudioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetAudio extends AudioEvent {}

class AudioPositionUpdated extends AudioEvent {
  final Duration position;

  AudioPositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

class SeekAudio extends AudioEvent {
  final Duration newPosition;

  SeekAudio(this.newPosition);

  @override
  List<Object?> get props => [newPosition];
}

class UpdateVisualizerBars extends AudioEvent {
  final List<double> barHeights;

  UpdateVisualizerBars(this.barHeights);

  @override
  List<Object?> get props => [barHeights];
}

class ResetVisualizerBars extends AudioEvent {}

class StartVisualizer extends AudioEvent {}

class StopVisualizer extends AudioEvent {}