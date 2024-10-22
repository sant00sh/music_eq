import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_bloc.dart';
import 'package:music_eq/presentation/bloc/audio_event.dart';
import 'package:music_eq/presentation/pages/audio_player_page.dart';
import 'core/constants/index.dart';
import 'injection.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioBloc>(
          create: (_) => di.sl<AudioBloc>()..add(GetAudio()),
        ),
      ],
      child: const MaterialApp(
        title: Titles.appName,
        debugShowCheckedModeBanner: false,
        home: AudioPlayerPage(),
      ),
    );
  }
}
