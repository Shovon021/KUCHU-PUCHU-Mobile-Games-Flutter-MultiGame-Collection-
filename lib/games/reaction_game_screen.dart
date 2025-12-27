import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class ReactionGameScreen extends StatefulWidget {
  const ReactionGameScreen({super.key});

  @override
  State<ReactionGameScreen> createState() => _ReactionGameScreenState();
}

class _ReactionGameScreenState extends State<ReactionGameScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color player1Color = Color(0xFFE53935);
  static const Color player2Color = Color(0xFF1E88E5);
  static const Color waitColor = Color(0xFFE53935);
  static const Color goColor = Color(0xFF43A047);

  int round = 0;
  int maxRounds = 5;
  List<int> scores = [0, 0];
  List<int> reactionTimes = [0, 0];
  
  bool waitingForGreen = false;
  bool greenLight = false;
  bool tooEarly = false;
  int? roundWinner;
  DateTime? greenLightTime;
  Timer? greenTimer;
  
  String message = '';
  bool gameStarted = false;
  int? gameWinner;

  final Random _random = Random();

  void _startGame() {
    setState(() {
      round = 0;
      scores = [0, 0];
      gameStarted = true;
      gameWinner = null;
    });
    _startRound();
  }

  void _startRound() {
    setState(() {
      round++;
      waitingForGreen = true;
      greenLight = false;
      tooEarly = false;
      roundWinner = null;
      reactionTimes = [0, 0];
      message = 'WAIT...';
    });

    int delay = 2000 + _random.nextInt(3000);
    greenTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      SoundService.playTick();
      setState(() {
        greenLight = true;
        greenLightTime = DateTime.now();
        waitingForGreen = false;
        message = 'TAP!';
      });
    });
  }

  void _onPlayerTap(int player) {
    if (!gameStarted || gameWinner != null || tooEarly) return;
    
    if (waitingForGreen && !greenLight) {
      greenTimer?.cancel();
      int otherPlayer = player == 1 ? 2 : 1;
      SoundService.playFail();
      setState(() {
        tooEarly = true;
        roundWinner = otherPlayer;
        scores[otherPlayer - 1]++;
        message = 'TOO EARLY!';
      });
      _checkGameEnd();
      return;
    }

    if (greenLight && roundWinner == null) {
      int reactionTime = DateTime.now().difference(greenLightTime!).inMilliseconds;
      SoundService.playSuccess();
      setState(() {
        reactionTimes[player - 1] = reactionTime;
        roundWinner = player;
        scores[player - 1]++;
        message = '${reactionTime}ms';
      });
      _checkGameEnd();
    }
  }

  void _checkGameEnd() {
    if (round >= maxRounds || scores[0] > maxRounds / 2 || scores[1] > maxRounds / 2) {
      setState(() {
        gameWinner = scores[0] > scores[1] ? 1 : (scores[1] > scores[0] ? 2 : 0);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showGameOverDialog();
      });
    }
  }

  void _showGameOverDialog() {
    Color winnerColor = gameWinner == 1 ? player1Color : (gameWinner == 2 ? player2Color : Colors.amber);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: winnerColor, shape: BoxShape.circle),
              child: AppIcons.trophy(size: 40, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(
              gameWinner == 0 ? "It's a Tie!" : "Player $gameWinner Wins!",
              style: TextStyle(color: winnerColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniScore(1, player1Color),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('vs', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                _buildMiniScore(2, player2Color),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: goColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(int player, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text('P$player: ${scores[player - 1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  @override
  void dispose() {
    greenTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildStartScreen();
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.back(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reaction Game', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AppIcons.help(),
            onPressed: () => showHowToPlay(context, GameRules.reactionGame),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [goColor, Color(0xFF66BB6A)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: goColor.withAlpha(100), blurRadius: 30, spreadRadius: 5)],
              ),
              child: AppIcons.flash(size: 60, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text('Reaction Game', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            const Text('Who has faster reflexes?', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  const Text('How to Play', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark)),
                  const SizedBox(height: 15),
                  _buildInstruction('hourglass', 'Wait for the screen to turn', waitColor, 'RED'),
                  _buildInstruction('hand-tap', 'When it turns', goColor, 'GREEN, TAP!'),
                  _buildInstruction('warning', 'Tap too early?', Colors.orange, 'Opponent wins!'),
                  _buildInstruction('trophy', 'Best of', Colors.amber, '5 rounds'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: goColor,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcons.svg('play', size: 28, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String iconName, String text, Color accentColor, String accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AppIcons.svg(iconName, size: 20, color: accentColor),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(accent, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    Color bgColor = greenLight ? goColor : waitColor;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, bgColor.withAlpha(200)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: AppIcons.svg('close', size: 28, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Round $round / $maxRounds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(30),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: player1Color, shape: BoxShape.circle)),
                          Text(' ${scores[0]} - ${scores[1]} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: player2Color, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Player 2 tap area (top, rotated for face-to-face)
              Expanded(
                child: Transform.rotate(
                  angle: pi,
                  child: _buildPlayerTapArea(2),
                ),
              ),

              // Center message area
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 15)],
                ),
                child: Column(
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: tooEarly ? waitColor : (greenLight ? goColor : textDark),
                      ),
                    ),
                    if (roundWinner != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        tooEarly ? 'Player ${roundWinner == 1 ? 2 : 1} was too early!' : 'Player $roundWinner wins!',
                        style: TextStyle(fontSize: 14, color: roundWinner == 1 ? player1Color : player2Color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),

              // Next round button
              if (roundWinner != null && gameWinner == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    icon: AppIcons.svg('arrow-forward', size: 24, color: Colors.white),
                    label: const Text('Next Round', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(50),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white, width: 2)),
                    ),
                    onPressed: _startRound,
                  ),
                ),

              // Player 1 tap area (bottom)
              Expanded(
                child: _buildPlayerTapArea(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerTapArea(int player) {
    Color playerColor = player == 1 ? player1Color : player2Color;
    bool isWinner = roundWinner == player;
    bool isLoser = roundWinner != null && roundWinner != player;
    
    return GestureDetector(
      onTap: () => _onPlayerTap(player),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWinner ? Colors.white : Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isWinner ? playerColor : Colors.white, width: 4),
          boxShadow: isWinner ? [BoxShadow(color: playerColor.withAlpha(100), blurRadius: 20, spreadRadius: 5)] : [],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isWinner ? playerColor : (isLoser ? Colors.grey : Colors.white.withAlpha(50)),
                  shape: BoxShape.circle,
                ),
                child: isWinner 
                  ? AppIcons.svg('check', size: 40, color: Colors.white)
                  : (isLoser 
                    ? AppIcons.svg('close', size: 40, color: Colors.white) 
                    : AppIcons.svg('hand-tap', size: 40, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              // Player name
              Text(
                'Player $player',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? playerColor : Colors.white,
                ),
              ),
              // Reaction time
              if (reactionTimes[player - 1] > 0) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: isWinner ? playerColor : Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${reactionTimes[player - 1]}ms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isWinner ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
