import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class SnakeLadderScreen extends StatefulWidget {
  const SnakeLadderScreen({super.key});

  @override
  State<SnakeLadderScreen> createState() => _SnakeLadderScreenState();
}

class _SnakeLadderScreenState extends State<SnakeLadderScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  static const List<Color> playerColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFDD835), // Yellow
  ];
  static const List<String> playerNames = ['Red', 'Blue', 'Green', 'Yellow'];

  // Game state
  int? numPlayers; // null = show selection screen
  List<int> playerPositions = [0, 0, 0, 0];
  int currentPlayer = 0;
  int diceValue = 1;
  bool canRoll = true;
  bool isRolling = false;
  bool isMoving = false;
  int? winner;
  String statusMessage = '';

  // Snakes: head -> tail (EXACTLY matching reference image)
  final Map<int, int> snakes = {
    27: 1,   // Big snake: 27 drops to 1 (longest!)
    22: 3,   // Snake: 22 drops to 3
    17: 4,   // Snake: 17 drops to 4
    19: 8,   // Snake: 19 drops to 8
  };

  // Ladders: bottom -> top (EXACTLY matching reference image)
  final Map<int, int> ladders = {
    2: 23,   // Big ladder: 2 climbs to 23
    5: 8,    // Small ladder: 5 climbs to 8
    11: 26,  // Big ladder: 11 climbs to 26
    20: 29,  // Ladder: 20 climbs to 29
  };

  final Random _random = Random();

  void _startGame(int players) {
    setState(() {
      numPlayers = players;
      playerPositions = [0, 0, 0, 0];
      currentPlayer = 0;
      diceValue = 1;
      canRoll = true;
      isMoving = false;
      winner = null;
      statusMessage = 'Tap dice to roll!';
    });
  }

  void _rollDice() async {
    if (!canRoll || isRolling || isMoving) return;

    setState(() { isRolling = true; statusMessage = 'Rolling...'; });

    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => diceValue = _random.nextInt(6) + 1);
    }

    SoundService.playTick();
    setState(() { isRolling = false; canRoll = false; statusMessage = 'Rolled $diceValue!'; });
    await Future.delayed(const Duration(milliseconds: 500));
    await _movePiece();
  }

  Future<void> _movePiece() async {
    int currentPos = playerPositions[currentPlayer];
    int targetPos = currentPos + diceValue;

    if (targetPos > 30) {
      setState(() => statusMessage = 'Need exact roll!');
      await Future.delayed(const Duration(milliseconds: 1000));
      _nextPlayer();
      return;
    }

    setState(() => isMoving = true);

    for (int step = currentPos + 1; step <= targetPos; step++) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() { playerPositions[currentPlayer] = step; statusMessage = 'Moving to $step...'; });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    int landedOn = playerPositions[currentPlayer];

    if (snakes.containsKey(landedOn)) {
      int dest = snakes[landedOn]!;
      SoundService.playFail();
      setState(() => statusMessage = '🐍 Snake! Down to $dest');
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => playerPositions[currentPlayer] = dest);
    } else if (ladders.containsKey(landedOn)) {
      int dest = ladders[landedOn]!;
      SoundService.playJump();
      setState(() => statusMessage = '🪜 Ladder! Up to $dest');
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => playerPositions[currentPlayer] = dest);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isMoving = false);

    if (playerPositions[currentPlayer] == 30) {
      SoundService.playLevelComplete();
      setState(() { winner = currentPlayer; statusMessage = '🎉 ${playerNames[currentPlayer]} wins!'; });
      await Future.delayed(const Duration(milliseconds: 500));
      _showWinDialog();
      return;
    }

    if (diceValue == 6) {
      setState(() { canRoll = true; statusMessage = '🎲 Rolled 6! Roll again!'; });
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _nextPlayer();
    }
  }

  void _nextPlayer() {
    setState(() {
      currentPlayer = (currentPlayer + 1) % numPlayers!;
      canRoll = true;
      statusMessage = '${playerNames[currentPlayer]}\'s turn!';
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            AppIcons.trophy(size: 60, color: Colors.amber),
            const SizedBox(height: 10),
            Text('${playerNames[winner!]} Wins!', style: TextStyle(color: playerColors[winner!], fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); _startGame(numPlayers!); },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() => numPlayers = null); },
            child: const Text('Change Players'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (numPlayers == null) return _buildPlayerSelection();
    if (numPlayers == 2) return _build2PlayerLayout();
    return _build4PlayerLayout();
  }

  // Player selection screen
  Widget _buildPlayerSelection() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Snakes & Ladders', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐍🪜', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            const Text('Select Players', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _playerCountButton(2, '2 Players', 'Face-to-Face'),
                const SizedBox(width: 20),
                _playerCountButton(4, '4 Players', 'Corners'),
              ],
            ),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.snakeLadder),
              icon: AppIcons.help(),
              label: const Text('How to Play?', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerCountButton(int count, String title, String subtitle) {
    return GestureDetector(
      onTap: () => _startGame(count),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            count == 2 ? AppIcons.people(size: 40, color: const Color(0xFF11998E)) : AppIcons.groups(size: 40, color: const Color(0xFF11998E)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // 2-player face-to-face layout
  Widget _build2PlayerLayout() {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // Player 2 (Top - Rotated 180°)
            Expanded(flex: 2, child: Transform.rotate(angle: pi, child: _buildPlayerPanel(1))),
            // Board
            Expanded(flex: 6, child: _buildBoardArea()),
            // Player 1 (Bottom)
            Expanded(flex: 2, child: _buildPlayerPanel(0, showNav: true)),
          ],
        ),
      ),
    );
  }

  // 4-player corner layout
  Widget _build4PlayerLayout() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Snakes & Ladders', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: AppIcons.refresh(), onPressed: () => _startGame(4))],
      ),
      body: Column(
        children: [
          // Top row: Player 1 (Red) - left, Player 2 (Blue) - right
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: Transform.rotate(angle: pi / 2, child: _buildCornerPlayer(0))), // Top-left, rotated 90° CW
                Expanded(child: Transform.rotate(angle: -pi / 2, child: _buildCornerPlayer(1))), // Top-right, rotated 90° CCW
              ],
            ),
          ),
          // Board
          Expanded(flex: 3, child: _buildBoardArea()),
          // Bottom row: Player 3 (Green) - left, Player 4 (Yellow) - right
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: Transform.rotate(angle: pi / 2, child: _buildCornerPlayer(2))), // Bottom-left
                Expanded(child: Transform.rotate(angle: -pi / 2, child: _buildCornerPlayer(3))), // Bottom-right
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerPlayer(int idx) {
    bool isActive = currentPlayer == idx && winner == null;
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? playerColors[idx] : playerColors[idx].withAlpha(100),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text('${playerNames[idx]}: ${playerPositions[idx]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: (canRoll && !isRolling && !isMoving) ? _rollDice : null,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: canRoll ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: playerColors[idx], width: 2),
                ),
                child: Center(child: Text(isRolling ? '🎲' : '$diceValue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: playerColors[idx]))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerPanel(int idx, {bool showNav = false}) {
    bool isActive = currentPlayer == idx && winner == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showNav)
            Row(
              children: [
                IconButton(icon: AppIcons.back(size: 20), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                IconButton(icon: AppIcons.refresh(size: 20), onPressed: () => _startGame(2)),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? playerColors[idx] : playerColors[idx].withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${playerNames[idx]}: ${playerPositions[idx]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (isActive) ...[
                const SizedBox(width: 10),
                Text(statusMessage, style: TextStyle(color: playerColors[idx], fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: (canRoll && !isRolling && !isMoving) ? _rollDice : null,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: canRoll ? Colors.white : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: playerColors[idx], width: 2),
                    ),
                    child: Center(child: Text(isRolling ? '🎲' : '$diceValue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: playerColors[idx]))),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(builder: (ctx, cons) => Stack(children: [_buildBoard(), ..._buildPieces(cons.maxWidth)])),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cellSize = constraints.maxWidth / 6;
        return Stack(
          children: [
            // Grid cells
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
              itemCount: 30,
              itemBuilder: (context, index) {
                int boardNum = _getBoardNumber(index);
                bool isSnakeHead = snakes.containsKey(boardNum);
                bool isSnakeTail = snakes.containsValue(boardNum);
                bool isLadderBottom = ladders.containsKey(boardNum);
                bool isLadderTop = ladders.containsValue(boardNum);
                bool isFinish = boardNum == 30;
                bool isStart = boardNum == 1;

                Color cellColor;
                if (isFinish) cellColor = const Color(0xFF4CAF50);
                else if (isStart) cellColor = const Color(0xFFE3F2FD);
                else if (isSnakeHead) cellColor = const Color(0xFFFFCDD2);
                else if (isLadderBottom) cellColor = const Color(0xFFC8E6C9);
                else { int r = index ~/ 6, c = index % 6; cellColor = (r + c) % 2 == 0 ? const Color(0xFFFFF8E1) : Colors.white; }

                return Container(
                  decoration: BoxDecoration(color: cellColor, border: Border.all(color: Colors.grey.shade300, width: 0.5)),
                  child: Stack(children: [
                    Positioned(left: 2, top: 1, child: Text('$boardNum', style: TextStyle(fontSize: 10, color: textDark.withAlpha(200), fontWeight: FontWeight.bold))),
                    if (isFinish) const Center(child: Text('🏁', style: TextStyle(fontSize: 20))),
                    if (isStart) const Center(child: Text('🚀', style: TextStyle(fontSize: 14))),
                  ]),
                );
              },
            ),
            // Draw snakes and ladders on top
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxWidth),
              painter: SnakeLadderPainter(
                snakes: snakes,
                ladders: ladders,
                cellSize: cellSize,
                getBoardNumber: _getBoardNumber,
                getGridIndex: _getGridIndex,
              ),
            ),
          ],
        );
      },
    );
  }

  // Traditional Snake & Ladder board layout:
  // Row 5 (top):    25 26 27 28 29 30  (left to right)
  // Row 4:          24 23 22 21 20 19  (right to left)
  // Row 3:          13 14 15 16 17 18  (left to right)
  // Row 2:          12 11 10  9  8  7  (right to left)
  // Row 1 (bottom):  1  2  3  4  5  6  (left to right)
  int _getBoardNumber(int gridIndex) {
    int row = gridIndex ~/ 6;  // 0 = top row in grid
    int col = gridIndex % 6;
    int boardRow = 4 - row;  // Convert: grid row 0 = board row 4 (top)
    
    if (boardRow % 2 == 0) {
      // Even rows (0, 2, 4): left to right
      return boardRow * 6 + col + 1;
    } else {
      // Odd rows (1, 3): right to left
      return boardRow * 6 + (5 - col) + 1;
    }
  }
  
  int _getGridIndex(int boardNum) {
    for (int i = 0; i < 30; i++) {
      if (_getBoardNumber(i) == boardNum) return i;
    }
    return 0;
  }

  List<Widget> _buildPieces(double size) {
    List<Widget> pieces = [];
    double cell = size / 6;
    for (int i = 0; i < numPlayers!; i++) {
      int pos = playerPositions[i];
      if (pos > 0 && pos <= 30) {
        int idx = _getGridIndex(pos);
        int r = idx ~/ 6, c = idx % 6;
        double ox = (i % 2) * 10 - 5, oy = (i ~/ 2) * 10 - 5;
        pieces.add(AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: c * cell + cell / 2 - 10 + ox,
          top: r * cell + cell / 2 - 10 + oy,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: playerColors[i], shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: playerColors[i].withAlpha(150), blurRadius: 4)],
            ),
          ),
        ));
      }
    }
    return pieces;
  }
}

// Custom painter to draw snakes and ladders visually
class SnakeLadderPainter extends CustomPainter {
  final Map<int, int> snakes;
  final Map<int, int> ladders;
  final double cellSize;
  final int Function(int) getBoardNumber;
  final int Function(int) getGridIndex;

  SnakeLadderPainter({
    required this.snakes,
    required this.ladders,
    required this.cellSize,
    required this.getBoardNumber,
    required this.getGridIndex,
  });

  Offset _getCellCenter(int boardNum) {
    int gridIndex = getGridIndex(boardNum);
    int row = gridIndex ~/ 6;
    int col = gridIndex % 6;
    return Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ladders first (behind snakes)
    _drawLadders(canvas);
    // Draw snakes on top
    _drawSnakes(canvas);
  }

  void _drawLadders(Canvas canvas) {
    final sidePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rungPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var entry in ladders.entries) {
      Offset bottom = _getCellCenter(entry.key);
      Offset top = _getCellCenter(entry.value);
      
      // Calculate perpendicular offset for ladder sides
      Offset dir = (top - bottom);
      double len = dir.distance;
      Offset perp = Offset(-dir.dy / len, dir.dx / len) * (cellSize * 0.2);
      
      // Draw two side rails
      canvas.drawLine(bottom + perp, top + perp, sidePaint);
      canvas.drawLine(bottom - perp, top - perp, sidePaint);
      
      // Draw rungs
      int numRungs = (len / (cellSize * 0.5)).round().clamp(2, 12);
      for (int i = 1; i < numRungs; i++) {
        double t = i / numRungs;
        Offset rungCenter = Offset.lerp(bottom, top, t)!;
        canvas.drawLine(rungCenter + perp, rungCenter - perp, rungPaint);
      }
    }
  }

  void _drawSnakes(Canvas canvas) {
    for (var entry in snakes.entries) {
      Offset head = _getCellCenter(entry.key);
      Offset tail = _getCellCenter(entry.value);
      
      // Snake body paint
      final bodyPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Create smooth curved snake path using quadratic bezier
      Path snakePath = Path();
      snakePath.moveTo(head.dx, head.dy);
      
      Offset direction = tail - head;
      double distance = direction.distance;
      
      // Create 2-3 curves for snake body
      int curves = (distance / cellSize).round().clamp(2, 4);
      
      for (int i = 0; i < curves; i++) {
        double t1 = i / curves;
        double t2 = (i + 1) / curves;
        
        Offset start = Offset.lerp(head, tail, t1)!;
        Offset end = Offset.lerp(head, tail, t2)!;
        
        // Alternate curve direction
        double curveAmount = (i % 2 == 0 ? 1 : -1) * cellSize * 0.4;
        Offset perp = Offset(-direction.dy / distance, direction.dx / distance);
        Offset control = Offset.lerp(start, end, 0.5)! + perp * curveAmount;
        
        snakePath.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      }
      
      // Draw snake body
      canvas.drawPath(snakePath, bodyPaint);
      
      // Draw darker outline
      canvas.drawPath(snakePath, bodyPaint
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke);
      canvas.drawPath(snakePath, bodyPaint
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 8);

      // Draw snake head
      final headPaint = Paint()..color = const Color(0xFF2E7D32);
      canvas.drawCircle(head, 12, headPaint);
      canvas.drawCircle(head, 10, Paint()..color = const Color(0xFF4CAF50));
      
      // Draw eyes
      canvas.drawCircle(head + const Offset(-4, -3), 3, Paint()..color = Colors.white);
      canvas.drawCircle(head + const Offset(4, -3), 3, Paint()..color = Colors.white);
      canvas.drawCircle(head + const Offset(-4, -3), 1.5, Paint()..color = Colors.black);
      canvas.drawCircle(head + const Offset(4, -3), 1.5, Paint()..color = Colors.black);
      
      // Draw tail (smaller circle)
      canvas.drawCircle(tail, 5, Paint()..color = const Color(0xFF4CAF50));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
