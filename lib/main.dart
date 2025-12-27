import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/score_service.dart';
import 'services/theme_service.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/player_stats_service.dart';
import 'services/ai_difficulty_service.dart';
import 'services/achievements_service.dart';
import 'services/high_score_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScoreService.init();
  await ThemeService.instance.init();
  await MusicService.instance.init();
  await SoundService.init();
  await playerStats.init();
  await aiDifficulty.init();
  await achievements.init();
  await HighScoreService.init();
  runApp(const GameBoxApp());
}

class GameBoxApp extends StatefulWidget {
  const GameBoxApp({super.key});

  @override
  State<GameBoxApp> createState() => _GameBoxAppState();
}

class _GameBoxAppState extends State<GameBoxApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'কুচু-পুচু',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.instance.getThemeData(),
      home: const SplashScreen(),
    );
  }
}
