import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../services/sound_service.dart';
import '../services/ai_difficulty_service.dart';
import '../services/player_stats_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  // Theme colors
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color player1Color = Color(0xFFFF6B6B); // Red/Coral for X
  static const Color player2Color = Color(0xFF4ECDC4); // Teal for O

  // Game mode
  bool? isVsAI; // null = show mode selection, true = vs AI, false = vs Player

  // Game state
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  int player1Score = 0;
  int player2Score = 0;
  String? winner;
  List<int> winningLine = [];
  bool isAIThinking = false;
  
  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _selectMode(bool vsAI) {
    setState(() {
      isVsAI = vsAI;
      _resetGame();
    });
  }

  void _handleTap(int index) {
    if (board[index].isNotEmpty || winner != null || isAIThinking) return;
    if (isVsAI == true && !isXTurn) return; // Don't allow taps during AI turn

    SoundService.playTap();
    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      isXTurn = !isXTurn;
    });

    _checkWinner();

    // If vs AI and no winner yet, let AI play
    if (isVsAI == true && winner == null && !isXTurn) {
      _aiMove();
    }
  }

  void _aiMove() async {
    setState(() => isAIThinking = true);
    
    // Small delay to make AI feel more natural
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted || winner != null) return;

    int bestMove = _getBestMove();
    
    if (bestMove != -1) {
      SoundService.playTap();
      setState(() {
        board[bestMove] = 'O';
        isXTurn = true;
        isAIThinking = false;
      });
      _checkWinner();
    } else {
      setState(() => isAIThinking = false);
    }
  }

  // AI with difficulty levels
  int _getBestMove() {
    final difficulty = aiDifficulty.difficulty;
    
    // Check if AI should make a random move (based on difficulty)
    if (math.Random().nextDouble() < difficulty.mistakeChance) {
      // Make a random valid move
      List<int> emptySpots = [];
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) emptySpots.add(i);
      }
      if (emptySpots.isNotEmpty) {
        return emptySpots[math.Random().nextInt(emptySpots.length)];
      }
    }
    
    // Use minimax with depth limit based on difficulty
    int bestScore = -1000;
    int bestMove = -1;
    int maxDepth = difficulty.searchDepth;

    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O';
        int score = _minimax(board, 0, false, maxDepth);
        board[i] = '';
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _minimax(List<String> b, int depth, bool isMaximizing, int maxDepth) {
    String? result = _checkWinnerForMinimax(b);
    if (result != null) {
      if (result == 'O') return 10 - depth;
      if (result == 'X') return depth - 10;
      return 0; // Draw
    }
    
    // Depth limit based on difficulty
    if (depth >= maxDepth) return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (b[i].isEmpty) {
          b[i] = 'O';
          int score = _minimax(b, depth + 1, false, maxDepth);
          b[i] = '';
          bestScore = math.max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (b[i].isEmpty) {
          b[i] = 'X';
          int score = _minimax(b, depth + 1, true, maxDepth);
          b[i] = '';
          bestScore = math.min(score, bestScore);
        }
      }
      return bestScore;
    }
  }

  String? _checkWinnerForMinimax(List<String> b) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      if (b[pattern[0]].isNotEmpty &&
          b[pattern[0]] == b[pattern[1]] &&
          b[pattern[1]] == b[pattern[2]]) {
        return b[pattern[0]];
      }
    }
    if (!b.contains('')) return 'Draw';
    return null;
  }

  void _checkWinner() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]].isNotEmpty &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        SoundService.playSuccess();
        setState(() {
          winner = board[pattern[0]];
          winningLine = pattern;
          if (winner == 'X') {
            player1Score++;
            // Track stats
            if (isVsAI == true) {
              playerStats.recordWin(PlayerStatsService.ticTacToe, vsComputer: true);
            }
            // Play confetti for player win
            _confettiController.play();
          } else {
            player2Score++;
            if (isVsAI == true) {
              playerStats.recordLoss(PlayerStatsService.ticTacToe);
            }
          }
        });
        _showResultDialog();
        return;
      }
    }

    if (!board.contains('')) {
      SoundService.playFail();
      setState(() => winner = 'Draw');
      if (isVsAI == true) {
        playerStats.recordDraw(PlayerStatsService.ticTacToe);
      }
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    String title;
    if (winner == 'Draw') {
      title = "It's a Draw!";
    } else if (isVsAI == true) {
      title = winner == 'X' ? 'You Win! 🎉' : 'AI Wins! 🤖';
    } else {
      title = '${winner == 'X' ? 'Player 1' : 'Player 2'} Wins!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(color: winner == 'X' ? player1Color : (winner == 'O' ? player2Color : textDark)),
          textAlign: TextAlign.center,
        ),
        content: winner == 'Draw' 
          ? AppIcons.handshake(size: 60, color: Colors.grey)
          : AppIcons.trophy(size: 60, color: Colors.amber),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      isXTurn = true;
      winner = null;
      winningLine = [];
      isAIThinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isVsAI == null) return _buildModeSelection();
    return Stack(
      children: [
        _buildGameScreen(),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.teal,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Tic Tac Toe', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppIcons.tag(size: 60, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text('Choose Game Mode', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 40),
            _modeButton('Play vs Friend', 'people', player2Color, () => _selectMode(false)),
            const SizedBox(height: 15),
            _modeButton('Play vs Computer', 'robot', player1Color, () => _selectMode(true)),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.ticTacToe),
              icon: AppIcons.help(),
              label: const Text('How to Play?', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String text, String iconName, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.svg(iconName, size: 24, color: Colors.white),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // Player 2 / AI - TOP (Rotated 180°)
            Expanded(
              flex: 2,
              child: Transform.rotate(
                angle: isVsAI == true ? 0 : math.pi,
                child: _buildPlayerArea(
                  playerName: isVsAI == true ? 'AI 🤖' : 'Player 2',
                  symbol: 'O',
                  score: player2Score,
                  color: player2Color,
                  isActive: !isXTurn && winner == null,
                  showBackButton: isVsAI == true,
                  isThinking: isAIThinking,
                ),
              ),
            ),

            // Game Board - CENTER
            Expanded(
              flex: 5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(15),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) => _buildCell(index),
                    ),
                  ),
                ),
              ),
            ),

            // Player 1 (X) - BOTTOM
            Expanded(
              flex: 2,
              child: _buildPlayerArea(
                playerName: isVsAI == true ? 'You' : 'Player 1',
                symbol: 'X',
                score: player1Score,
                color: player1Color,
                isActive: isXTurn && winner == null,
                showBackButton: true,
                isThinking: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea({
    required String playerName,
    required String symbol,
    required int score,
    required Color color,
    required bool isActive,
    required bool showBackButton,
    required bool isThinking,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBackButton)
            Row(
              children: [
                IconButton(
                  icon: AppIcons.back(),
                  onPressed: () => setState(() => isVsAI = null),
                ),
                const Spacer(),
                IconButton(
                  icon: AppIcons.help(color: textDark),
                  onPressed: () => showHowToPlay(context, GameRules.ticTacToe),
                ),
                IconButton(
                  icon: AppIcons.refresh(),
                  onPressed: _resetGame,
                ),
              ],
            ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isActive ? color : color.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive ? [BoxShadow(color: color.withAlpha(100), blurRadius: 10)] : [],
                ),
                child: Center(
                  child: Text(symbol, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 15),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isActive ? textDark : Colors.grey)),
                  Text('Score: $score', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              
              if (isActive && !isThinking) ...[
                const SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text(isVsAI == true && symbol == 'X' ? 'YOUR TURN' : 'TURN', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
              
              if (isThinking) ...[
                const SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('THINKING...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int index) {
    bool isWinningCell = winningLine.contains(index);
    String value = board[index];
    Color cellColor = value == 'X' ? player1Color : (value == 'O' ? player2Color : Colors.white);

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: value.isEmpty ? Colors.white : cellColor.withAlpha(isWinningCell ? 255 : 200),
          borderRadius: BorderRadius.circular(15),
          border: isWinningCell
              ? Border.all(color: Colors.amber, width: 3)
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: value.isNotEmpty ? [BoxShadow(color: cellColor.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Center(
          child: Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
