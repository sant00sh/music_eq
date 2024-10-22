import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_eq/core/constants/index.dart';
import 'package:music_eq/core/utils/extensions.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_event.dart';
import 'package:music_eq/presentation/bloc/audio_state.dart';
import 'package:music_eq/presentation/widgets/equalizer_visualizer.dart';
import 'package:music_eq/presentation/widgets/loading_indicator.dart';

class AudioPlayerPage extends StatefulWidget {
  const AudioPlayerPage({super.key});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late AudioBloc _audioBloc;

  @override
  void initState() {
    super.initState();
    _audioBloc = context.read<AudioBloc>();
    _audioBloc.add(GetAudio());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Titles.appName),
      ),
      body: BlocBuilder<AudioBloc, AudioState>(
        builder: (context, state) {
          if (state is AudioInitial) {
            return _buildInitialState();
          } else if (state is AudioLoading) {
            return _buildLoadingState();
          } else if (state is AudioLoaded) {
            return _buildLoadedState(state);
          } else if (state is AudioError) {
            return _buildErrorState(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Text(Labels.pressToPlay),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingIndicator(),
    );
  }

  Widget _buildLoadedState(AudioLoaded state) {
    return Column(
      children: [
        Expanded(
          child: EqualizerVisualizer(
            audioPlayer: _audioBloc.audioPlayer,
            audioFilePath: state.audioFile.url,
          ),
        ),
        _buildDurationDisplay(state),
        _buildControls(state),
      ],
    );
  }

  Widget _buildDurationDisplay(AudioLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '${_formatDuration(state.currentPosition)} / ${_formatDuration(_audioBloc.audioPlayer.duration ?? Duration.zero)}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildControls(AudioLoaded state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: StreamBuilder<bool>(
        stream: _audioBloc.audioPlayer.playingStream,
        builder: (context, playingSnapshot) {
          return StreamBuilder<ProcessingState>(
            stream: _audioBloc.audioPlayer.processingStateStream,
            builder: (context, processingSnapshot) {
              final isPlaying = playingSnapshot.data ?? false;
              final processingState =
                  processingSnapshot.data ?? ProcessingState.idle;

              final bool showPlayIcon =
                  !isPlaying || processingState == ProcessingState.completed;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      size: 36,
                    ),
                    onPressed: () {
                      _audioBloc.add(SeekAudio(Duration.zero));
                      if (processingState == ProcessingState.completed) {
                        _audioBloc.audioPlayer.play();
                      }
                    },
                  ),
                  16.toHorizontalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 64,
                      icon: Icon(
                        showPlayIcon
                            ? Icons.play_circle_filled
                            : Icons.pause_circle_filled,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        if (processingState == ProcessingState.completed) {
                          _audioBloc.add(SeekAudio(Duration.zero));
                          _audioBloc.audioPlayer.play();
                        } else if (isPlaying) {
                          _audioBloc.audioPlayer.pause();
                        } else {
                          _audioBloc.audioPlayer.play();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      size: 36,
                    ),
                    onPressed: null,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(AudioError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error: ${state.message}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          16.toVerticalSpace,
          ElevatedButton(
            onPressed: () {
              _audioBloc.add(GetAudio());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
