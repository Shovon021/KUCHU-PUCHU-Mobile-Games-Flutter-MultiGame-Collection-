import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class NumberGuessScreen extends StatefulWidget {
  const NumberGuessScreen({super.key});

  @override
  State<NumberGuessScreen> createState() => _NumberGuessScreenState();
}

class _NumberGuessScreenState extends State<NumberGuessScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color player1Color = Color(0xFFE53935);
  static const Color player2Color = Color(0xFF1E88E5);
  static const Color correctColor = Color(0xFF43A047);

  int secretNumber = 0;
  int minRange = 1;
  int maxRange = 100;
  int currentGuess = 50;
  int currentPlayer = 1;
  List<int> scores = [0, 0];
  int round = 1;
  int maxRounds = 5;
  String hint = '';
  String lastGuessHint = '';
  int? roundWinner;
  int? gameWinner;
  bool gameStarted = false;

  final Random _random = Random();

  void _startGame() {
    setState(() { scores = [0, 0]; round = 1; gameWinner = null; gameStarted = true; });
    _startRound();
  }

  void _startRound() {
    setState(() {
      secretNumber = _random.nextInt(100) + 1;
      minRange = 1; maxRange = 100; currentGuess = 50;
      currentPlayer = round % 2 == 1 ? 1 : 2;
      roundWinner = null; hint = 'Find the secret number!'; lastGuessHint = '';
    });
  }

  void _adjustGuess(int delta) {
    setState(() => currentGuess = (currentGuess + delta).clamp(minRange, maxRange));
  }

  void _makeGuess() {
    if (currentGuess == secretNumber) {
      SoundService.playSuccess();
      setState(() {
        roundWinner = currentPlayer; scores[currentPlayer - 1]++;
        hint = '🎉 Correct! It was $secretNumber!'; lastGuessHint = '';
      });
      _checkGameEnd();
    } else if (currentGuess < secretNumber) {
      SoundService.playMove();
      setState(() {
        lastGuessHint = '$currentGuess is TOO LOW! ⬆️'; minRange = currentGuess + 1;
        currentGuess = ((minRange + maxRange) / 2).round();
        currentPlayer = currentPlayer == 1 ? 2 : 1;
        hint = 'Between $minRange - $maxRange';
      });
    } else {
      SoundService.playMove();
      setState(() {
        lastGuessHint = '$currentGuess is TOO HIGH! ⬇️'; maxRange = currentGuess - 1;
        currentGuess = ((minRange + maxRange) / 2).round();
        currentPlayer = currentPlayer == 1 ? 2 : 1;
        hint = 'Between $minRange - $maxRange';
      });
    }
  }

  void _checkGameEnd() {
    if (round >= maxRounds || scores[0] > maxRounds / 2 || scores[1] > maxRounds / 2) {
      setState(() => gameWinner = scores[0] > scores[1] ? 1 : (scores[1] > scores[0] ? 2 : 0));
      Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _showGameOverDialog(); });
    }
  }

  void _nextRound() { if (gameWinner != null) return; setState(() => round++); _startRound(); }

  void _showGameOverDialog() {
    Color winnerColor = gameWinner == 1 ? player1Color : (gameWinner == 2 ? player2Color : Colors.amber);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(children: [
          AppIcons.trophy(size: 50, color: winnerColor),
          const SizedBox(height: 10),
          Text(gameWinner == 0 ? "It's a Tie!" : "Player $gameWinner Wins!", style: TextStyle(color: winnerColor, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('${scores[0]} - ${scores[1]}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)), onPressed: () { Navigator.pop(context); _startGame(); }, child: const Text('Play Again', style: TextStyle(color: Colors.white)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildStartScreen();
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)), title: const Text('Number Guess', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(icon: AppIcons.help(), onPressed: () => showHowToPlay(context, GameRules.numberGuess))]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)]), shape: BoxShape.circle),
              child: const Text('?', style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Text('Number Guess', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark)),
            const Text('Higher or Lower?', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20), margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Column(children: [
                Text('How to Play', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                Text('🎯 Secret number: 1-100'),
                Text('🔢 Take turns guessing'),
                Text('⬆️⬇️ Get Higher/Lower hints'),
                Text('🏆 Find it first to win!'),
              ]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    Color activeColor = currentPlayer == 1 ? player1Color : player2Color;
    
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)), title: Text('Round $round / $maxRounds', style: const TextStyle(color: textDark, fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(icon: AppIcons.refresh(), onPressed: _startGame)]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Scores row
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildScoreCard(1), _buildScoreCard(2)]),
              const SizedBox(height: 10),
              
              // Current player
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: roundWinner != null ? correctColor : activeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(roundWinner == null ? "Player $currentPlayer's Turn" : "Player $roundWinner Found It!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),

              // Hint area
              Container(
                width: double.infinity, padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Column(children: [
                  if (lastGuessHint.isNotEmpty) Text(lastGuessHint, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: lastGuessHint.contains('LOW') ? player1Color : player2Color)),
                  Text(hint, style: TextStyle(fontSize: 14, color: roundWinner != null ? correctColor : Colors.grey.shade700)),
                ]),
              ),

              const Spacer(),

              if (roundWinner == null) ...[
                // Number selector
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildAdjustButton('remove', currentGuess > minRange, activeColor, () => _adjustGuess(-1), () => _adjustGuess(-10)),
                  const SizedBox(width: 15),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: activeColor.withAlpha(100), blurRadius: 15)]),
                    child: Center(child: Text('$currentGuess', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 15),
                  _buildAdjustButton('add', currentGuess < maxRange, activeColor, () => _adjustGuess(1), () => _adjustGuess(10)),
                ]),
                const SizedBox(height: 8),
                Text('Range: $minRange - $maxRange', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 15),

                // Slider
                SliderTheme(
                  data: SliderThemeData(activeTrackColor: activeColor, inactiveTrackColor: activeColor.withAlpha(50), thumbColor: activeColor, trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10)),
                  child: Slider(value: currentGuess.toDouble(), min: minRange.toDouble(), max: maxRange.toDouble(), onChanged: (v) => setState(() => currentGuess = v.round())),
                ),
                const SizedBox(height: 15),

                // Guess button
                ElevatedButton(onPressed: _makeGuess, style: ElevatedButton.styleFrom(backgroundColor: activeColor, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('GUESS!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ] else ...[
                // Winner display
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: correctColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: correctColor.withAlpha(100), blurRadius: 20)]),
                  child: Center(child: Text('$secretNumber', style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 10),
                const Text('was the number!', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                if (gameWinner == null)
                  ElevatedButton(onPressed: _nextRound, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('Next Round', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustButton(String iconName, bool enabled, Color color, VoidCallback onTap, VoidCallback onLongPress) {
    return GestureDetector(
      onTap: enabled ? onTap : null, onLongPress: enabled ? onLongPress : null,
      child: Container(width: 50, height: 50, decoration: BoxDecoration(color: enabled ? color : Colors.grey.shade300, borderRadius: BorderRadius.circular(12)), child: Center(child: AppIcons.svg(iconName, size: 25, color: Colors.white))),
    );
  }

  Widget _buildScoreCard(int player) {
    Color color = player == 1 ? player1Color : player2Color;
    bool isActive = currentPlayer == player && roundWinner == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: isActive ? color : color.withAlpha(100), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Text('P$player', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text('${scores[player - 1]}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
