import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_eq/core/utils/extensions.dart';
import 'package:music_eq/presentation/widgets/loading_indicator.dart';
import 'package:waveform_extractor/model/waveform.dart';
import 'package:waveform_extractor/waveform_extractor.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_event.dart';
import 'package:music_eq/presentation/bloc/audio_state.dart';

class EqualizerVisualizer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String audioFilePath;
  final int barsCount;
  final double minHeight;

  const EqualizerVisualizer({
    super.key,
    required this.audioPlayer,
    required this.audioFilePath,
    this.barsCount = 100,
    this.minHeight = 0.1,
  });

  @override
  State<EqualizerVisualizer> createState() => _EqualizerVisualizerState();
}

class _EqualizerVisualizerState extends State<EqualizerVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _processingStateSubscription;
  Timer? _timer;
  late AudioBloc _audioBloc;
  final waveformExtractor = WaveformExtractor();
  Waveform? _waveformData;
  bool isExtracting = false;
  List<double> _baseWaveform = [];

  @override
  void initState() {
    super.initState();
    _audioBloc = context.read<AudioBloc>();
    _setupAnimation();
    _listenToPlayback();
    _extractWaveform();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  Future<void> _extractWaveform() async {
    try {
      setState(() => isExtracting = true);
      _waveformData =
          await waveformExtractor.extractWaveform(widget.audioFilePath);
      if (_waveformData != null) {
        _generateBaseWaveform();
      }
    } catch (_) {} finally {
      setState(() => isExtracting = false);
    }
  }

  void _generateBaseWaveform() {
    if (_waveformData == null) return;

    final waveformData = _waveformData!.waveformData;
    _baseWaveform = [];

    final samplesPerBar = (waveformData.length / widget.barsCount).ceil();

    for (int i = 0; i < widget.barsCount; i++) {
      final startSample = i * samplesPerBar;
      final endSample = math.min((i + 1) * samplesPerBar, waveformData.length);

      if (startSample >= waveformData.length) break;

      double sum = 0;
      int count = 0;
      for (int j = startSample; j < endSample; j++) {
        if (j < waveformData.length) {
          sum += waveformData[j];
          count++;
        }
      }
      double average = count > 0 ? sum / count : 0;

      double normalizedHeight = (average / 255).clamp(widget.minHeight, 1.0);

      final variation = math.sin(i * 0.2) * 0.1;
      normalizedHeight =
          (normalizedHeight + variation).clamp(widget.minHeight, 1.0);

      _baseWaveform.add(normalizedHeight);
    }

    _smoothWaveform();
  }

  void _smoothWaveform() {
    final smoothed = List<double>.from(_baseWaveform);
    const smoothingFactor = 3;

    for (int i = smoothingFactor;
        i < _baseWaveform.length - smoothingFactor;
        i++) {
      double sum = 0;
      for (int j = -smoothingFactor; j <= smoothingFactor; j++) {
        sum += _baseWaveform[i + j];
      }
      smoothed[i] = sum / (2 * smoothingFactor + 1);
    }

    _baseWaveform = smoothed;
  }

  void _listenToPlayback() {
    _playerStateSubscription =
        widget.audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        if (playing) {
          _startAnimation();
        } else {
          if (widget.audioPlayer.processingState != ProcessingState.completed) {
            _stopAnimation();
          }
        }
      }
    });

    _processingStateSubscription =
        widget.audioPlayer.processingStateStream.listen((state) {
      if (mounted && state == ProcessingState.completed) {
        _stopAnimation();
        _audioBloc.add(ResetVisualizerBars());
      }
    });
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted &&
          widget.audioPlayer.playing &&
          widget.audioPlayer.processingState != ProcessingState.completed) {
        _updateBars();
      }
    });
  }

  void _stopAnimation() {
    _timer?.cancel();
    if (mounted && _baseWaveform.isNotEmpty) {
      _audioBloc.add(UpdateVisualizerBars(_baseWaveform));
    }
  }

  void _updateBars() {
    if (_baseWaveform.isEmpty) return;

    final duration = widget.audioPlayer.duration;

    if (duration == null) return;

    final newBarHeights = List<double>.from(_baseWaveform);

    if (mounted) {
      _audioBloc.add(UpdateVisualizerBars(newBarHeights));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is AudioLoaded) {
          return Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color.fromARGB(255, 40, 40, 40)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: isExtracting
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const LoadingIndicator(),
                              16.toVerticalSpace,
                              // Text('Extracting waveform...'),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              state.barHeights.length,
                              (index) => _buildBar(
                                index,
                                state.barHeights,
                                widget.audioPlayer.position,
                                widget.audioPlayer.duration ?? Duration.zero,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              _buildProgressBar(),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildBar(int index, List<double> barHeights, Duration position,
      Duration duration) {
    final color = Theme.of(context).primaryColor;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final barPosition = index / barHeights.length;
    final isPlayed = barPosition <= progress;

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 300 * barHeights[index],
          decoration: BoxDecoration(
            color: isPlayed ? color : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.audioPlayer.duration ?? Duration.zero;

        final currentPosition = position.inMilliseconds
            .toDouble()
            .clamp(0, duration.inMilliseconds.toDouble());

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: currentPosition.toDouble(),
                  min: 0,
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) async {
                    final newPosition = Duration(milliseconds: value.round());
                    await widget.audioPlayer.seek(newPosition);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position)),
                    Text(_formatDuration(duration)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
