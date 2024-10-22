import 'package:equatable/equatable.dart';

class AudioFile extends Equatable {
  final String url;
  final String title;

  const AudioFile({required this.url, required this.title});

  @override
  List<Object?> get props => [url, title];
}