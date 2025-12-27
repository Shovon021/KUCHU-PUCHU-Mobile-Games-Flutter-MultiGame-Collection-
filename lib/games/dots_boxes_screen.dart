import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class DotsBoxesScreen extends StatefulWidget {
  const DotsBoxesScreen({super.key});

  @override
  State<DotsBoxesScreen> createState() => _DotsBoxesScreenState();
}

class _DotsBoxesScreenState extends State<DotsBoxesScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color player1Color = Color(0xFFE53935); // Red
  static const Color player2Color = Color(0xFF1E88E5); // Blue
  static const Color lineDefault = Color(0xFFE0E0E0);

  // Grid size selection
  int? gridSize; // null = show selection, 3 = 3x3 boxes, 4 = 4x4 boxes, 5 = 5x5 boxes
  int dotCount = 0;
  int boxCount = 0;

  // Game state
  late List<List<int>> horizontalLines;
  late List<List<int>> verticalLines;
  late List<List<int>> boxes;
  
  int currentPlayer = 1;
  List<int> scores = [0, 0];
  int? winner;

  void _startGame(int size) {
    setState(() {
      gridSize = size;
      dotCount = size + 1;
      boxCount = size;
      horizontalLines = List.generate(dotCount, (_) => List.filled(boxCount, 0));
      verticalLines = List.generate(boxCount, (_) => List.filled(dotCount, 0));
      boxes = List.generate(boxCount, (_) => List.filled(boxCount, 0));
      currentPlayer = 1;
      scores = [0, 0];
      winner = null;
    });
  }

  void _drawHorizontalLine(int row, int col) {
    if (horizontalLines[row][col] != 0 || winner != null) return;
    SoundService.playTap();
    setState(() => horizontalLines[row][col] = currentPlayer);
    _checkBoxes();
  }

  void _drawVerticalLine(int row, int col) {
    if (verticalLines[row][col] != 0 || winner != null) return;
    SoundService.playTap();
    setState(() => verticalLines[row][col] = currentPlayer);
    _checkBoxes();
  }

  void _checkBoxes() {
    bool completedBox = false;

    for (int row = 0; row < boxCount; row++) {
      for (int col = 0; col < boxCount; col++) {
        if (boxes[row][col] == 0 && _isBoxComplete(row, col)) {
          SoundService.playCoin();
          setState(() {
            boxes[row][col] = currentPlayer;
            scores[currentPlayer - 1]++;
          });
          completedBox = true;
        }
      }
    }

    // Check game over
    int totalBoxes = boxCount * boxCount;
    if (scores[0] + scores[1] == totalBoxes) {
      setState(() {
        if (scores[0] > scores[1]) winner = 1;
        else if (scores[1] > scores[0]) winner = 2;
        else winner = 0;
      });
      SoundService.playSuccess();
      _showWinDialog();
      return;
    }

    // Switch player if no box completed
    if (!completedBox) {
      setState(() => currentPlayer = currentPlayer == 1 ? 2 : 1);
    }
  }

  bool _isBoxComplete(int row, int col) {
    return horizontalLines[row][col] != 0 &&
           horizontalLines[row + 1][col] != 0 &&
           verticalLines[row][col] != 0 &&
           verticalLines[row][col + 1] != 0;
  }

  void _showWinDialog() {
    String title = winner == 0 ? "It's a Tie! 🤝" : "${winner == 1 ? 'Red' : 'Blue'} Wins! 🎉";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            winner == 0 
              ? AppIcons.handshake(size: 50, color: Colors.grey)
              : AppIcons.trophy(size: 50, color: winner == 1 ? player1Color : (winner == 2 ? player2Color : Colors.amber)),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(
              color: winner == 1 ? player1Color : (winner == 2 ? player2Color : textDark), 
              fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Red: ${scores[0]} | Blue: ${scores[1]}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); _startGame(gridSize!); },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() => gridSize = null); },
            child: const Text('Change Grid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gridSize == null) return _buildGridSelection();
    return _buildGameScreen();
  }

  Widget _buildGridSelection() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Dots & Boxes', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⬜', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            const Text('Select Grid Size', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 10),
            const Text('Draw lines to complete boxes!', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _gridButton(3, '3×3', 'Quick'),
                const SizedBox(width: 15),
                _gridButton(4, '4×4', 'Normal'),
                const SizedBox(width: 15),
                _gridButton(5, '5×5', 'Long'),
              ],
            ),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.dotsBoxes),
              icon: AppIcons.help(),
              label: const Text('How to Play?', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridButton(int size, String title, String desc) {
    return GestureDetector(
      onTap: () => _startGame(size),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withAlpha(30), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
            const SizedBox(height: 5),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text('${size * size} boxes', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
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
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Dots & Boxes', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: AppIcons.refresh(), onPressed: () => _startGame(gridSize!))],
      ),
      body: Column(
        children: [
          // Scores
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerScore(1, 'Red', player1Color),
                _buildPlayerScore(2, 'Blue', player2Color),
              ],
            ),
          ),

          // Current player indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: currentPlayer == 1 ? player1Color : player2Color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (currentPlayer == 1 ? player1Color : player2Color).withAlpha(100), blurRadius: 10)],
            ),
            child: Text(
              winner == null ? "${currentPlayer == 1 ? 'Red' : 'Blue'}'s Turn - Draw a line!" : "Game Over!",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Game board
          Expanded(child: _buildBoard()),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(int player, String name, Color color) {
    bool isActive = currentPlayer == player && winner == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color : color.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive ? [BoxShadow(color: color.withAlpha(100), blurRadius: 10)] : [],
      ),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('${scores[player - 1]}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)))),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double size = constraints.maxWidth;
              double cellSize = size / dotCount;
              double dotSize = 14;
              double lineThickness = 6;

              return Stack(
                children: [
                  // Filled boxes
                  ..._buildFilledBoxes(cellSize, dotSize),
                  // Horizontal lines
                  ..._buildHorizontalLines(cellSize, dotSize, lineThickness),
                  // Vertical lines
                  ..._buildVerticalLines(cellSize, dotSize, lineThickness),
                  // Dots
                  ..._buildDots(cellSize, dotSize),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilledBoxes(double cellSize, double dotSize) {
    List<Widget> widgets = [];
    for (int row = 0; row < boxCount; row++) {
      for (int col = 0; col < boxCount; col++) {
        if (boxes[row][col] != 0) {
          widgets.add(Positioned(
            left: col * cellSize + dotSize,
            top: row * cellSize + dotSize,
            child: Container(
              width: cellSize - dotSize * 1.5,
              height: cellSize - dotSize * 1.5,
              decoration: BoxDecoration(
                color: (boxes[row][col] == 1 ? player1Color : player2Color).withAlpha(60),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  boxes[row][col] == 1 ? 'R' : 'B',
                  style: TextStyle(
                    color: boxes[row][col] == 1 ? player1Color : player2Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ));
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildHorizontalLines(double cellSize, double dotSize, double thickness) {
    List<Widget> widgets = [];
    for (int row = 0; row < dotCount; row++) {
      for (int col = 0; col < boxCount; col++) {
        int lineState = horizontalLines[row][col];
        Color lineColor = lineState == 0 ? lineDefault : (lineState == 1 ? player1Color : player2Color);
        
        widgets.add(Positioned(
          left: col * cellSize + dotSize,
          top: row * cellSize + dotSize / 2 - thickness / 2,
          child: GestureDetector(
            onTap: () => _drawHorizontalLine(row, col),
            child: Container(
              width: cellSize - dotSize,
              height: thickness + 20, // Extra tap area
              color: Colors.transparent,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cellSize - dotSize,
                  height: thickness,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(thickness / 2),
                    boxShadow: lineState != 0 ? [BoxShadow(color: lineColor.withAlpha(100), blurRadius: 4)] : [],
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildVerticalLines(double cellSize, double dotSize, double thickness) {
    List<Widget> widgets = [];
    for (int row = 0; row < boxCount; row++) {
      for (int col = 0; col < dotCount; col++) {
        int lineState = verticalLines[row][col];
        Color lineColor = lineState == 0 ? lineDefault : (lineState == 1 ? player1Color : player2Color);
        
        widgets.add(Positioned(
          left: col * cellSize + dotSize / 2 - thickness / 2,
          top: row * cellSize + dotSize,
          child: GestureDetector(
            onTap: () => _drawVerticalLine(row, col),
            child: Container(
              width: thickness + 20, // Extra tap area
              height: cellSize - dotSize,
              color: Colors.transparent,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: thickness,
                  height: cellSize - dotSize,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(thickness / 2),
                    boxShadow: lineState != 0 ? [BoxShadow(color: lineColor.withAlpha(100), blurRadius: 4)] : [],
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildDots(double cellSize, double dotSize) {
    List<Widget> widgets = [];
    for (int row = 0; row < dotCount; row++) {
      for (int col = 0; col < dotCount; col++) {
        widgets.add(Positioned(
          left: col * cellSize,
          top: row * cellSize,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: textDark,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 3, offset: const Offset(0, 2))],
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
