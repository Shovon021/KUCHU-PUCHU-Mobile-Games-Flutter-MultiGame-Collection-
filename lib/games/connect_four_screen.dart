import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/sound_service.dart';
import '../services/ai_difficulty_service.dart';
import '../services/player_stats_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color player1Color = Color(0xFFE53935); // Red
  static const Color player2Color = Color(0xFFFDD835); // Yellow
  static const Color boardColor = Color(0xFF1565C0); // Blue board

  // Game mode
  bool? isVsAI; // null = show mode selection

  // 6 rows x 7 columns
  List<List<int>> board = List.generate(6, (_) => List.filled(7, 0));
  int currentPlayer = 1; // 1 = Red (Human), 2 = Yellow (AI or Human)
  int? winner;
  List<List<int>> winningCells = [];
  List<int> scores = [0, 0];
  bool isAIThinking = false;

  final Random _random = Random();
  
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

  void _dropDisc(int col) {
    if (winner != null || isAIThinking) return;
    if (isVsAI == true && currentPlayer == 2) return; // Don't allow during AI turn

    // Find lowest empty row in column
    for (int row = 5; row >= 0; row--) {
      if (board[row][col] == 0) {
        SoundService.playTap();
        setState(() {
          board[row][col] = currentPlayer;
        });
        
        if (_checkWin(row, col)) {
          SoundService.playSuccess();
          setState(() {
            winner = currentPlayer;
            scores[currentPlayer - 1]++;
          });
          // Track stats and celebrate
          if (isVsAI == true && currentPlayer == 1) {
            playerStats.recordWin(PlayerStatsService.connectFour, vsComputer: true);
            _confettiController.play();
          }
          _showWinDialog();
          return;
        }
        
        if (_isBoardFull()) {
          SoundService.playFail();
          if (isVsAI == true) {
            playerStats.recordDraw(PlayerStatsService.connectFour);
          }
          _showDrawDialog();
          return;
        }
        
        setState(() => currentPlayer = currentPlayer == 1 ? 2 : 1);
        
        // AI move
        if (isVsAI == true && currentPlayer == 2 && winner == null) {
          _aiMove();
        }
        return;
      }
    }
  }

  void _aiMove() async {
    setState(() => isAIThinking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted || winner != null) return;

    int bestCol = _getBestMove();
    
    // Find lowest empty row
    for (int row = 5; row >= 0; row--) {
      if (board[row][bestCol] == 0) {
        SoundService.playTap();
        setState(() {
          board[row][bestCol] = 2;
          isAIThinking = false;
        });
        
        if (_checkWin(row, bestCol)) {
          SoundService.playSuccess();
          setState(() {
            winner = 2;
            scores[1]++;
          });
          // AI wins = player loses
          if (isVsAI == true) {
            playerStats.recordLoss(PlayerStatsService.connectFour);
          }
          _showWinDialog();
          return;
        }
        
        if (_isBoardFull()) {
          SoundService.playFail();
          _showDrawDialog();
          return;
        }
        
        setState(() => currentPlayer = 1);
        return;
      }
    }
    setState(() => isAIThinking = false);
  }

  int _getBestMove() {
    // 1. Check if AI can win
    for (int col = 0; col < 7; col++) {
      int row = _getLowestEmptyRow(col);
      if (row != -1) {
        board[row][col] = 2;
        if (_checkWinStatic(row, col, 2)) {
          board[row][col] = 0;
          return col;
        }
        board[row][col] = 0;
      }
    }
    
    // 2. Block player from winning
    for (int col = 0; col < 7; col++) {
      int row = _getLowestEmptyRow(col);
      if (row != -1) {
        board[row][col] = 1;
        if (_checkWinStatic(row, col, 1)) {
          board[row][col] = 0;
          return col;
        }
        board[row][col] = 0;
      }
    }
    
    // 3. Take center if available
    if (board[5][3] == 0) return 3;
    
    // 4. Score each column and pick best
    List<int> colScores = List.filled(7, 0);
    for (int col = 0; col < 7; col++) {
      int row = _getLowestEmptyRow(col);
      if (row == -1) {
        colScores[col] = -1000;
        continue;
      }
      
      // Prefer center columns
      colScores[col] = 10 - (col - 3).abs() * 2;
      
      // Check potential threats
      board[row][col] = 2;
      colScores[col] += _countThreats(2) * 5;
      board[row][col] = 0;
    }
    
    int bestScore = colScores.reduce(max);
    List<int> bestCols = [];
    for (int i = 0; i < 7; i++) {
      if (colScores[i] == bestScore) bestCols.add(i);
    }
    
    return bestCols[_random.nextInt(bestCols.length)];
  }

  int _getLowestEmptyRow(int col) {
    for (int row = 5; row >= 0; row--) {
      if (board[row][col] == 0) return row;
    }
    return -1;
  }

  int _countThreats(int player) {
    int threats = 0;
    // Check for 3-in-a-row opportunities
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 7; col++) {
        if (board[row][col] == player) {
          // Horizontal
          if (col <= 3) {
            int count = 0;
            for (int i = 0; i < 4; i++) {
              if (board[row][col + i] == player) count++;
              else if (board[row][col + i] != 0) count = -10;
            }
            if (count >= 3) threats++;
          }
          // Vertical
          if (row <= 2) {
            int count = 0;
            for (int i = 0; i < 4; i++) {
              if (board[row + i][col] == player) count++;
              else if (board[row + i][col] != 0) count = -10;
            }
            if (count >= 3) threats++;
          }
        }
      }
    }
    return threats;
  }

  bool _checkWinStatic(int row, int col, int player) {
    List<List<int>> directions = [[0, 1], [1, 0], [1, 1], [1, -1]];
    for (var dir in directions) {
      int count = 1;
      for (int sign in [-1, 1]) {
        int r = row + dir[0] * sign;
        int c = col + dir[1] * sign;
        while (r >= 0 && r < 6 && c >= 0 && c < 7 && board[r][c] == player) {
          count++;
          r += dir[0] * sign;
          c += dir[1] * sign;
        }
      }
      if (count >= 4) return true;
    }
    return false;
  }

  bool _checkWin(int row, int col) {
    int player = board[row][col];
    List<List<int>> directions = [[0, 1], [1, 0], [1, 1], [1, -1]];

    for (var dir in directions) {
      List<List<int>> cells = [[row, col]];
      for (int sign in [-1, 1]) {
        int r = row + dir[0] * sign;
        int c = col + dir[1] * sign;
        while (r >= 0 && r < 6 && c >= 0 && c < 7 && board[r][c] == player) {
          cells.add([r, c]);
          r += dir[0] * sign;
          c += dir[1] * sign;
        }
      }
      if (cells.length >= 4) {
        winningCells = cells;
        return true;
      }
    }
    return false;
  }

  bool _isBoardFull() => board[0].every((cell) => cell != 0);

  bool _isWinningCell(int row, int col) => winningCells.any((cell) => cell[0] == row && cell[1] == col);

  void _showWinDialog() {
    String title;
    if (isVsAI == true) {
      title = winner == 1 ? 'You Win! 🎉' : 'AI Wins! 🤖';
    } else {
      title = '${winner == 1 ? "Red" : "Yellow"} Wins!';
    }
    
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            AppIcons.trophy(size: 50, color: winner == 1 ? player1Color : player2Color),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: winner == 1 ? player1Color : player2Color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Red: ${scores[0]} | Yellow: ${scores[1]}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: boardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); _resetGame(); },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            AppIcons.handshake(size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("It's a Draw!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: boardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); _resetGame(); },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      board = List.generate(6, (_) => List.filled(7, 0));
      currentPlayer = 1;
      winner = null;
      winningCells = [];
      isAIThinking = false;
    });
  }

  String _getTurnText() {
    if (isAIThinking) return 'AI Thinking...';
    if (winner != null) return 'Game Over!';
    if (isVsAI == true) {
      return currentPlayer == 1 ? 'Your Turn' : "AI's Turn";
    }
    return currentPlayer == 1 ? "Red's Turn" : "Yellow's Turn";
  }

  @override
  Widget build(BuildContext context) {
    if (isVsAI == null) return _buildModeSelection();
    return _buildGameScreen();
  }

  Widget _buildModeSelection() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Connect Four', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(20)),
              child: AppIcons.svg('connect-four', size: 60, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text('Choose Game Mode', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 40),
            _modeButton('Play vs Friend', 'people', player2Color, () => _selectMode(false)),
            const SizedBox(height: 15),
            _modeButton('Play vs Computer', 'robot', player1Color, () => _selectMode(true)),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.connectFour),
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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 10, offset: const Offset(0, 5))]),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => setState(() => isVsAI = null)),
        title: const Text('Connect Four', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: AppIcons.refresh(), onPressed: _resetGame)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerScore(1, isVsAI == true ? 'You' : 'Red', player1Color),
                _buildPlayerScore(2, isVsAI == true ? 'AI' : 'Yellow', player2Color),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: currentPlayer == 1 ? player1Color : player2Color, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAIThinking) ...[
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 8),
                ],
                Text(
                  _getTurnText(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(child: _buildBoard()),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(int player, String name, Color color) {
    bool isActive = currentPlayer == player && winner == null && !isAIThinking;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: isActive ? color : color.withAlpha(100), borderRadius: BorderRadius.circular(15), boxShadow: isActive ? [BoxShadow(color: color.withAlpha(100), blurRadius: 10)] : []),
      child: Row(
        children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
          const SizedBox(width: 10),
          Text('$name: ${scores[player - 1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: 7 / 6,
        child: Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: boardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: boardColor.withAlpha(100), blurRadius: 15, offset: const Offset(0, 8))]),
          child: Column(
            children: List.generate(6, (row) => Expanded(
              child: Row(children: List.generate(7, (col) => Expanded(child: _buildCell(row, col)))),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    int cell = board[row][col];
    bool isWinning = _isWinningCell(row, col);
    
    return GestureDetector(
      onTap: () => _dropDisc(col),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cell == 0 ? Colors.white : (cell == 1 ? player1Color : player2Color),
          shape: BoxShape.circle,
          border: isWinning ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: cell != 0 ? [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
      ),
    );
  }
}
