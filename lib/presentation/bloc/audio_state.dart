import 'package:equatable/equatable.dart';
import 'package:music_eq/domain/entities/audio_file.dart';

abstract class AudioState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioLoaded extends AudioState {
  final AudioFile audioFile;
  final Duration currentPosition;
  final List<double> barHeights;

  AudioLoaded({
    required this.audioFile,
    this.currentPosition = Duration.zero,
    this.barHeights = const [],
  });

  AudioLoaded copyWith({
    AudioFile? audioFile,
    Duration? currentPosition,
    List<double>? barHeights,
  }) {
    return AudioLoaded(
      audioFile: audioFile ?? this.audioFile,
      currentPosition: currentPosition ?? this.currentPosition,
      barHeights: barHeights ?? this.barHeights,
    );
  }

  @override
  List<Object?> get props => [audioFile, currentPosition, barHeights];
}

class AudioError extends AudioState {
  final String message;

  AudioError({required this.message});

  @override
  List<Object?> get props => [message];
}