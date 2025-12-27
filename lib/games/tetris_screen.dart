import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../services/high_score_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

// Tetromino types
enum TetrominoType { I, O, T, L, J, S, Z }

// Tetromino colors
const Map<TetrominoType, Color> tetrominoColors = {
  TetrominoType.I: Color(0xFF00F0F0), // Cyan
  TetrominoType.O: Color(0xFFF0F000), // Yellow
  TetrominoType.T: Color(0xFFA000F0), // Purple
  TetrominoType.L: Color(0xFFF0A000), // Orange
  TetrominoType.J: Color(0xFF0000F0), // Blue
  TetrominoType.S: Color(0xFF00F000), // Green
  TetrominoType.Z: Color(0xFFF00000), // Red
};

// Tetromino shapes (rotation states)
const Map<TetrominoType, List<List<List<int>>>> tetrominoShapes = {
  TetrominoType.I: [
    [[0,0,0,0], [1,1,1,1], [0,0,0,0], [0,0,0,0]],
    [[0,0,1,0], [0,0,1,0], [0,0,1,0], [0,0,1,0]],
    [[0,0,0,0], [0,0,0,0], [1,1,1,1], [0,0,0,0]],
    [[0,1,0,0], [0,1,0,0], [0,1,0,0], [0,1,0,0]],
  ],
  TetrominoType.O: [
    [[1,1], [1,1]],
    [[1,1], [1,1]],
    [[1,1], [1,1]],
    [[1,1], [1,1]],
  ],
  TetrominoType.T: [
    [[0,1,0], [1,1,1], [0,0,0]],
    [[0,1,0], [0,1,1], [0,1,0]],
    [[0,0,0], [1,1,1], [0,1,0]],
    [[0,1,0], [1,1,0], [0,1,0]],
  ],
  TetrominoType.L: [
    [[0,0,1], [1,1,1], [0,0,0]],
    [[0,1,0], [0,1,0], [0,1,1]],
    [[0,0,0], [1,1,1], [1,0,0]],
    [[1,1,0], [0,1,0], [0,1,0]],
  ],
  TetrominoType.J: [
    [[1,0,0], [1,1,1], [0,0,0]],
    [[0,1,1], [0,1,0], [0,1,0]],
    [[0,0,0], [1,1,1], [0,0,1]],
    [[0,1,0], [0,1,0], [1,1,0]],
  ],
  TetrominoType.S: [
    [[0,1,1], [1,1,0], [0,0,0]],
    [[0,1,0], [0,1,1], [0,0,1]],
    [[0,0,0], [0,1,1], [1,1,0]],
    [[1,0,0], [1,1,0], [0,1,0]],
  ],
  TetrominoType.Z: [
    [[1,1,0], [0,1,1], [0,0,0]],
    [[0,0,1], [0,1,1], [0,1,0]],
    [[0,0,0], [1,1,0], [0,1,1]],
    [[0,1,0], [1,1,0], [1,0,0]],
  ],
};

class Tetromino {
  TetrominoType type;
  int rotation = 0;
  int x, y;

  Tetromino({required this.type, required this.x, required this.y});

  List<List<int>> get shape => tetrominoShapes[type]![rotation % 4];
  Color get color => tetrominoColors[type]!;
  
  int get size => shape.length;

  void rotateClockwise() => rotation = (rotation + 1) % 4;
  void rotateCounterClockwise() => rotation = (rotation + 3) % 4;
}

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  // Game constants
  static const int boardWidth = 10;
  static const int boardHeight = 20;
  static const Color emptyColor = Color(0xFF1a1a2e);
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  // Game state
  List<List<Color?>> board = List.generate(
    boardHeight, 
    (_) => List.filled(boardWidth, null),
  );
  
  Tetromino? currentPiece;
  Tetromino? nextPiece;
  TetrominoType? holdPiece;
  bool canHold = true;
  
  int score = 0;
  int lines = 0;
  int level = 1;
  int combo = 0;
  
  bool isPlaying = false;
  bool isGameOver = false;
  bool isPaused = false;
  bool showStartScreen = true;
  int highScore = 0;
  bool isNewHighScore = false;
  
  Timer? gameTimer;
  final Random _random = Random();

  // Speed (ms per drop) - gets faster with level
  int get dropSpeed => max(100, 800 - (level - 1) * 50);

  @override
  void initState() {
    super.initState();
    highScore = HighScoreService.getHighScore(HighScoreService.tetris);
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (showStartScreen) {
      setState(() => showStartScreen = false);
    }
    
    setState(() {
      board = List.generate(boardHeight, (_) => List.filled(boardWidth, null));
      score = 0;
      lines = 0;
      level = 1;
      combo = 0;
      isGameOver = false;
      isPaused = false;
      canHold = true;
      holdPiece = null;
      nextPiece = _generatePiece();
      _spawnNewPiece();
      isPlaying = true;
    });
    
    _startGameLoop();
  }

  void _startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: dropSpeed), (timer) {
      if (!isPaused && isPlaying && !isGameOver) {
        _moveDown();
      }
    });
  }

  Tetromino _generatePiece() {
    final type = TetrominoType.values[_random.nextInt(TetrominoType.values.length)];
    return Tetromino(
      type: type,
      x: boardWidth ~/ 2 - 2,
      y: 0,
    );
  }

  void _spawnNewPiece() {
    currentPiece = nextPiece ?? _generatePiece();
    currentPiece!.x = boardWidth ~/ 2 - currentPiece!.size ~/ 2;
    currentPiece!.y = 0;
    nextPiece = _generatePiece();
    canHold = true;

    // Check if spawn position is valid
    if (!_isValidPosition(currentPiece!)) {
      _gameOver();
    }
  }

  bool _isValidPosition(Tetromino piece, [int? testX, int? testY, int? testRotation]) {
    final x = testX ?? piece.x;
    final y = testY ?? piece.y;
    final oldRotation = piece.rotation;
    if (testRotation != null) piece.rotation = testRotation;
    final shape = piece.shape;
    if (testRotation != null) piece.rotation = oldRotation;

    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          final boardX = x + col;
          final boardY = y + row;
          
          if (boardX < 0 || boardX >= boardWidth || boardY >= boardHeight) {
            return false;
          }
          if (boardY >= 0 && board[boardY][boardX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _moveLeft() {
    if (currentPiece == null || !isPlaying || isPaused) return;
    if (_isValidPosition(currentPiece!, currentPiece!.x - 1, currentPiece!.y)) {
      setState(() => currentPiece!.x--);
    }
  }

  void _moveRight() {
    if (currentPiece == null || !isPlaying || isPaused) return;
    if (_isValidPosition(currentPiece!, currentPiece!.x + 1, currentPiece!.y)) {
      setState(() => currentPiece!.x++);
    }
  }

  void _moveDown() {
    if (currentPiece == null || !isPlaying || isPaused) return;
    if (_isValidPosition(currentPiece!, currentPiece!.x, currentPiece!.y + 1)) {
      setState(() => currentPiece!.y++);
    } else {
      _lockPiece();
    }
  }

  void _hardDrop() {
    if (currentPiece == null || !isPlaying || isPaused) return;
    int dropDistance = 0;
    while (_isValidPosition(currentPiece!, currentPiece!.x, currentPiece!.y + 1)) {
      currentPiece!.y++;
      dropDistance++;
    }
    score += dropDistance * 2; // Bonus for hard drop
    _lockPiece();
    SoundService.playTap();
  }

  void _rotate() {
    if (currentPiece == null || !isPlaying || isPaused) return;
    final newRotation = (currentPiece!.rotation + 1) % 4;
    
    // Try normal rotation
    if (_isValidPosition(currentPiece!, currentPiece!.x, currentPiece!.y, newRotation)) {
      setState(() => currentPiece!.rotateClockwise());
      SoundService.playTap();
      return;
    }
    
    // Wall kick - try shifting left/right
    for (int offset in [-1, 1, -2, 2]) {
      if (_isValidPosition(currentPiece!, currentPiece!.x + offset, currentPiece!.y, newRotation)) {
        setState(() {
          currentPiece!.x += offset;
          currentPiece!.rotateClockwise();
        });
        SoundService.playTap();
        return;
      }
    }
  }

  void _holdPiece() {
    if (currentPiece == null || !canHold || !isPlaying || isPaused) return;
    
    final currentType = currentPiece!.type;
    
    if (holdPiece != null) {
      currentPiece = Tetromino(
        type: holdPiece!,
        x: boardWidth ~/ 2 - 2,
        y: 0,
      );
    } else {
      _spawnNewPiece();
    }
    
    holdPiece = currentType;
    canHold = false;
    SoundService.playTap();
    setState(() {});
  }

  void _lockPiece() {
    if (currentPiece == null) return;
    
    final shape = currentPiece!.shape;
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          final boardY = currentPiece!.y + row;
          final boardX = currentPiece!.x + col;
          if (boardY >= 0 && boardY < boardHeight && boardX >= 0 && boardX < boardWidth) {
            board[boardY][boardX] = currentPiece!.color;
          }
        }
      }
    }
    
    _clearLines();
    _spawnNewPiece();
  }

  void _clearLines() {
    int linesCleared = 0;
    
    for (int row = boardHeight - 1; row >= 0; row--) {
      if (board[row].every((cell) => cell != null)) {
        // Remove this line
        board.removeAt(row);
        board.insert(0, List.filled(boardWidth, null));
        linesCleared++;
        row++; // Check same row again
      }
    }
    
    if (linesCleared > 0) {
      // Scoring: 100, 300, 500, 800 for 1, 2, 3, 4 lines
      final lineScores = [0, 100, 300, 500, 800];
      score += lineScores[linesCleared] * level;
      
      // Combo bonus
      if (combo > 0) {
        score += 50 * combo * level;
      }
      combo++;
      
      lines += linesCleared;
      
      // Level up every 10 lines
      final newLevel = (lines ~/ 10) + 1;
      if (newLevel > level) {
        level = newLevel;
        _startGameLoop(); // Update speed
      }
      
      SoundService.playSuccess();
      setState(() {});
    } else {
      combo = 0;
    }
  }

  void _gameOver() {
    gameTimer?.cancel();
    _saveHighScore();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    SoundService.playFail();
  }

  Future<void> _saveHighScore() async {
    isNewHighScore = await HighScoreService.setHighScore(HighScoreService.tetris, score);
    highScore = HighScoreService.getHighScore(HighScoreService.tetris);
  }

  void _togglePause() {
    setState(() => isPaused = !isPaused);
  }

  // Get ghost piece position (preview where piece will land)
  int _getGhostY() {
    if (currentPiece == null) return 0;
    int ghostY = currentPiece!.y;
    while (_isValidPosition(currentPiece!, currentPiece!.x, ghostY + 1)) {
      ghostY++;
    }
    return ghostY;
  }

  @override
  Widget build(BuildContext context) {
    if (showStartScreen) return _buildStartScreen();
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              switch (event.logicalKey) {
                case LogicalKeyboardKey.arrowLeft:
                  _moveLeft();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.arrowRight:
                  _moveRight();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.arrowDown:
                  _moveDown();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.arrowUp:
                case LogicalKeyboardKey.keyX:
                  _rotate();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.space:
                  _hardDrop();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.keyC:
                case LogicalKeyboardKey.shiftLeft:
                  _holdPiece();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.keyP:
                case LogicalKeyboardKey.escape:
                  _togglePause();
                  return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            children: [
              // Left panel - Hold & controls
              Expanded(
                flex: 2,
                child: _buildLeftPanel(),
              ),
              
              // Game board
              Expanded(
                flex: 3,
                child: _buildGameBoard(),
              ),
              
              // Right panel - Next & score
              Expanded(
                flex: 2,
                child: _buildRightPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    icon: AppIcons.back(color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Tetris logo with colored blocks
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniBlock(Colors.cyan),
                _buildMiniBlock(Colors.yellow),
                _buildMiniBlock(Colors.purple),
                _buildMiniBlock(Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'TETRIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Classic Brick Game',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcons.svg('play', size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('START', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.tetris),
              icon: AppIcons.help(color: Colors.white70),
              label: const Text('How to Play?', style: TextStyle(color: Colors.white70)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '← → Move  •  ↑ Rotate  •  ↓ Drop  •  Space Hard Drop',
                style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBlock(Color color) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 8)],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          IconButton(
            icon: AppIcons.back(color: Colors.white),
            onPressed: () {
              gameTimer?.cancel();
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          // Hold piece
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text('HOLD', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: holdPiece != null 
                    ? _buildPreviewPiece(holdPiece!, canHold ? 1.0 : 0.4)
                    : null,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Controls
          _buildControlButton('⟲', _rotate),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton('←', _moveLeft),
              const SizedBox(width: 10),
              _buildControlButton('→', _moveRight),
            ],
          ),
          const SizedBox(height: 10),
          _buildControlButton('↓', _moveDown),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _hardDrop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.cyan),
              ),
              child: const Text('DROP', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildControlButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          constraints.maxWidth / boardWidth,
          (constraints.maxHeight - 40) / boardHeight,
        );
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: cellSize * boardWidth + 4,
              height: cellSize * boardHeight + 4,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Board cells
                  CustomPaint(
                    size: Size(cellSize * boardWidth, cellSize * boardHeight),
                    painter: _TetrisBoardPainter(
                      board: board,
                      currentPiece: currentPiece,
                      ghostY: _getGhostY(),
                      cellSize: cellSize,
                    ),
                  ),
                  
                  // Pause overlay
                  if (isPaused)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text('PAUSED', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  
                  // Game over overlay
                  if (isGameOver) _buildGameOverOverlay(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Pause button
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
            onPressed: _togglePause,
          ),
          const Spacer(),
          // Next piece
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text('NEXT', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: nextPiece != null 
                    ? _buildPreviewPiece(nextPiece!.type, 1.0)
                    : null,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Score
          _buildStatBox('SCORE', '$score'),
          const SizedBox(height: 10),
          _buildStatBox('LINES', '$lines'),
          const SizedBox(height: 10),
          _buildStatBox('LEVEL', '$level'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPreviewPiece(TetrominoType type, double opacity) {
    final shape = tetrominoShapes[type]![0];
    final color = tetrominoColors[type]!.withAlpha((255 * opacity).toInt());
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: shape.map((row) => Row(
          mainAxisSize: MainAxisSize.min,
          children: row.map((cell) => Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: cell == 1 ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          )).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER', style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
            if (isNewHighScore)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏆 NEW HIGH SCORE! 🏆', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 15),
            Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('High Score: $highScore', style: TextStyle(color: Colors.amber.withAlpha(200), fontSize: 14)),
            const SizedBox(height: 5),
            Text('Lines: $lines', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14)),
            Text('Level: $level', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              child: const Text('Play Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TetrisBoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Tetromino? currentPiece;
  final int ghostY;
  final double cellSize;

  _TetrisBoardPainter({
    required this.board,
    required this.currentPiece,
    required this.ghostY,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw grid
    paint.color = Colors.white.withAlpha(10);
    for (int x = 0; x <= board[0].length; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        paint,
      );
    }
    for (int y = 0; y <= board.length; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        paint,
      );
    }

    // Draw board cells
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != null) {
          _drawCell(canvas, x, y, board[y][x]!, cellSize);
        }
      }
    }

    // Draw ghost piece
    if (currentPiece != null) {
      final shape = currentPiece!.shape;
      for (int row = 0; row < shape.length; row++) {
        for (int col = 0; col < shape[row].length; col++) {
          if (shape[row][col] == 1) {
            final x = currentPiece!.x + col;
            final y = ghostY + row;
            if (y >= 0) {
              paint.color = currentPiece!.color.withAlpha(50);
              paint.style = PaintingStyle.stroke;
              paint.strokeWidth = 1;
              canvas.drawRect(
                Rect.fromLTWH(x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2),
                paint,
              );
              paint.style = PaintingStyle.fill;
            }
          }
        }
      }
    }

    // Draw current piece
    if (currentPiece != null) {
      final shape = currentPiece!.shape;
      for (int row = 0; row < shape.length; row++) {
        for (int col = 0; col < shape[row].length; col++) {
          if (shape[row][col] == 1) {
            final x = currentPiece!.x + col;
            final y = currentPiece!.y + row;
            if (y >= 0) {
              _drawCell(canvas, x, y, currentPiece!.color, cellSize);
            }
          }
        }
      }
    }
  }

  void _drawCell(Canvas canvas, int x, int y, Color color, double size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(x * size + 1, y * size + 1, size - 2, size - 2);
    
    // Main color
    paint.color = color;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    
    // Highlight
    paint.color = Colors.white.withAlpha(80);
    canvas.drawLine(
      Offset(rect.left + 2, rect.top + 2),
      Offset(rect.right - 2, rect.top + 2),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left + 2, rect.top + 2),
      Offset(rect.left + 2, rect.bottom - 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TetrisBoardPainter old) => true;
}
