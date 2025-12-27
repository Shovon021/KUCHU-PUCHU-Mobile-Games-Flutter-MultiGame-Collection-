import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/score_service.dart';
import '../widgets/app_icons.dart';
import '../widgets/how_to_play.dart';

class SimonSaysScreen extends StatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  static const List<Color> buttonColors = [
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFFFDD835), // Yellow
  ];

  static const List<Color> buttonLitColors = [
    Color(0xFFFF6659),
    Color(0xFF76D275),
    Color(0xFF6AB7FF),
    Color(0xFFFFFF6B),
  ];

  List<int> sequence = [];
  List<int> playerInput = [];
  int score = 0;
  int highScore = 0;
  bool isShowingSequence = false;
  bool isPlayerTurn = false;
  bool gameOver = false;
  int? litButton;
  String message = 'Tap Start to Play!';

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Load saved high score
    highScore = ScoreService.getHighScore(GameIds.simonSays);
  }

  void _startGame() {
    SoundService.playTap();
    setState(() {
      sequence = [];
      playerInput = [];
      score = 0;
      gameOver = false;
      message = 'Watch the sequence...';
    });
    _nextRound();
  }

  void _nextRound() async {
    setState(() {
      playerInput = [];
      isShowingSequence = true;
      isPlayerTurn = false;
      message = 'Watch carefully...';
    });

    sequence.add(_random.nextInt(4));
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < sequence.length; i++) {
      if (!mounted) return;
      setState(() => litButton = sequence[i]);
      SoundService.playTick();
      await Future.delayed(Duration(milliseconds: 600 - (score * 20).clamp(0, 300)));
      if (!mounted) return;
      setState(() => litButton = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() {
      isShowingSequence = false;
      isPlayerTurn = true;
      message = 'Your turn! Repeat the pattern';
    });
  }

  void _onButtonTap(int index) async {
    if (!isPlayerTurn || gameOver || isShowingSequence) return;

    SoundService.playTap();
    setState(() => litButton = index);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => litButton = null);

    playerInput.add(index);

    int inputIndex = playerInput.length - 1;
    if (playerInput[inputIndex] != sequence[inputIndex]) {
      _gameOver();
      return;
    }

    if (playerInput.length == sequence.length) {
      SoundService.playSuccess();
      setState(() {
        score++;
        if (score > highScore) {
          highScore = score;
          ScoreService.saveHighScore(GameIds.simonSays, score);
          SoundService.playHighScore();
        }
        message = 'Correct! Level ${score + 1}...';
        isPlayerTurn = false;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      _nextRound();
    }
  }

  void _gameOver() {
    SoundService.playGameOver();
    setState(() {
      gameOver = true;
      isPlayerTurn = false;
      message = 'Game Over! Score: $score';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Simon Says', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AppIcons.help(),
            onPressed: () => showHowToPlay(context, GameRules.simonSays),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCard('Score', score, const Color(0xFF667EEA)),
                _buildScoreCard('High Score', highScore, const Color(0xFFFF8C42)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)]),
            child: Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(color: textDark, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20)]),
              padding: const EdgeInsets.all(10),
              child: GridView.count(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) => _buildColorButton(index)),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(30),
            child: ElevatedButton(
              onPressed: (isShowingSequence || isPlayerTurn) ? null : _startGame,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text(gameOver ? 'Play Again' : (score == 0 ? 'Start Game' : 'Restart'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text('$value', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildColorButton(int index) {
    bool isLit = litButton == index;
    return GestureDetector(
      onTap: () => _onButtonTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isLit ? buttonLitColors[index] : buttonColors[index],
          borderRadius: BorderRadius.circular(15),
          boxShadow: isLit ? [BoxShadow(color: buttonLitColors[index], blurRadius: 20, spreadRadius: 5)] : [],
        ),
      ),
    );
  }
}
