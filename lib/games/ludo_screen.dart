import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  static const Color redColor = Color(0xFFE53935);
  static const Color greenColor = Color(0xFF43A047);
  static const Color blueColor = Color(0xFF1E88E5);
  static const Color yellowColor = Color(0xFFFDD835);
  static const Color bgColor = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  int? numPlayers; // null = show selection screen
  int currentPlayer = 0;
  int diceValue = 1;
  bool canRoll = true;
  bool isRolling = false;

  List<List<int>> pieces = [
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
  ];

  void _startGame(int players) {
    setState(() {
      numPlayers = players;
      currentPlayer = 0;
      diceValue = 1;
      canRoll = true;
      pieces = [[-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1]];
    });
  }

  // CORRECTED 52-cell main path
  // Red enters at 0, Green at 13, Yellow at 26, Blue at 39
  static final List<Offset> mainPath = [
    // Red starts here (LEFT side, row 6) - going right then up
    Offset(1, 6),  // 0 - Red start ★
    Offset(2, 6),
    Offset(3, 6),
    Offset(4, 6),
    Offset(5, 6),
    Offset(6, 5),
    Offset(6, 4),
    Offset(6, 3),
    Offset(6, 2),  // 8 - Safe ★
    Offset(6, 1),
    Offset(6, 0),
    Offset(7, 0),
    Offset(8, 0),
    // Green starts here (TOP side, col 8) - going down then right
    Offset(8, 1),  // 13 - Green start ★
    Offset(8, 2),
    Offset(8, 3),
    Offset(8, 4),
    Offset(8, 5),
    Offset(9, 6),
    Offset(10, 6),
    Offset(11, 6),
    Offset(12, 6), // 21 - Safe ★
    Offset(13, 6),
    Offset(14, 6),
    Offset(14, 7),
    Offset(14, 8),
    // Yellow starts here (RIGHT side, row 8) - going left then down
    Offset(13, 8), // 26 - Yellow start ★
    Offset(12, 8),
    Offset(11, 8),
    Offset(10, 8),
    Offset(9, 8),
    Offset(8, 9),
    Offset(8, 10),
    Offset(8, 11),
    Offset(8, 12), // 34 - Safe ★
    Offset(8, 13),
    Offset(8, 14),
    Offset(7, 14),
    Offset(6, 14),
    // Blue starts here (BOTTOM side, col 6) - going up then left
    Offset(6, 13), // 39 - Blue start ★
    Offset(6, 12),
    Offset(6, 11),
    Offset(6, 10),
    Offset(6, 9),
    Offset(5, 8),
    Offset(4, 8),
    Offset(3, 8),
    Offset(2, 8),  // 47 - Safe ★
    Offset(1, 8),
    Offset(0, 8),
    Offset(0, 7),
    Offset(0, 6),  // 51 - completes loop back to before Red
  ];

  // Start positions: Red=0, Green=13, Yellow=26, Blue=39
  static const List<int> startPositions = [0, 13, 26, 39];

  // Home lanes for each player
  static final List<List<Offset>> homeLanes = [
    // Red - LEFT to center
    [Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7), Offset(6, 7)],
    // Green - TOP to center
    [Offset(7, 1), Offset(7, 2), Offset(7, 3), Offset(7, 4), Offset(7, 5), Offset(7, 6)],
    // Yellow - RIGHT to center
    [Offset(13, 7), Offset(12, 7), Offset(11, 7), Offset(10, 7), Offset(9, 7), Offset(8, 7)],
    // Blue - BOTTOM to center
    [Offset(7, 13), Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9), Offset(7, 8)],
  ];

  // Home base positions (where pieces sit before entering)
  static final List<List<Offset>> homePositions = [
    [Offset(1.5, 1.5), Offset(3.5, 1.5), Offset(1.5, 3.5), Offset(3.5, 3.5)], // Red
    [Offset(10.5, 1.5), Offset(12.5, 1.5), Offset(10.5, 3.5), Offset(12.5, 3.5)], // Green
    [Offset(10.5, 10.5), Offset(12.5, 10.5), Offset(10.5, 12.5), Offset(12.5, 12.5)], // Yellow (bottom-right!)
    [Offset(1.5, 10.5), Offset(3.5, 10.5), Offset(1.5, 12.5), Offset(3.5, 12.5)], // Blue (bottom-left!)
  ];

  static const List<int> safeSpots = [0, 8, 13, 21, 26, 34, 39, 47];

  final Random _random = Random();

  Color getPlayerColor(int player) {
    switch (player) {
      case 0: return redColor;
      case 1: return greenColor;
      case 2: return yellowColor;
      case 3: return blueColor;
      default: return redColor;
    }
  }

  String getPlayerName(int player) {
    switch (player) {
      case 0: return 'Red';
      case 1: return 'Green';
      case 2: return 'Yellow';
      case 3: return 'Blue';
      default: return 'Red';
    }
  }

  Offset? getPiecePosition(int player, int pathPos) {
    if (pathPos == -1) return null;
    if (pathPos >= 57) return const Offset(7, 7);

    if (pathPos >= 52) {
      int laneIndex = pathPos - 52;
      if (laneIndex < homeLanes[player].length) {
        return homeLanes[player][laneIndex];
      }
      return const Offset(7, 7);
    }

    int absolutePos = (pathPos + startPositions[player]) % 52;
    return mainPath[absolutePos];
  }

  void _rollDice() async {
    if (!canRoll || isRolling) return;
    setState(() => isRolling = true);

    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) setState(() => diceValue = _random.nextInt(6) + 1);
    }

    SoundService.playTick();
    setState(() { isRolling = false; canRoll = false; });

    if (!_canMove()) {
      await Future.delayed(const Duration(milliseconds: 600));
      _nextPlayer();
    }
  }

  bool _canMove() {
    for (int i = 0; i < 4; i++) {
      int pos = pieces[currentPlayer][i];
      if (pos == -1 && diceValue == 6) return true;
      if (pos >= 0 && pos < 57 && pos + diceValue <= 57) return true;
    }
    return false;
  }

  void _movePiece(int pieceIndex) {
    if (canRoll) return;
    int pos = pieces[currentPlayer][pieceIndex];

    if (pos == -1) {
      if (diceValue == 6) {
        SoundService.playTap();
        setState(() => pieces[currentPlayer][pieceIndex] = 0);
        _checkCapture(0);
        _afterMove();
      }
      return;
    }

    int newPos = pos + diceValue;
    if (pos < 52 && newPos >= 52) {
      int stepsToHome = 51 - pos;
      if (diceValue > stepsToHome) {
        int homeLanePos = 52 + (diceValue - stepsToHome - 1);
        if (homeLanePos <= 57) {
          setState(() => pieces[currentPlayer][pieceIndex] = homeLanePos);
          _afterMove();
        }
        return;
      }
    }

    if (newPos <= 57) {
      setState(() => pieces[currentPlayer][pieceIndex] = newPos);
      if (newPos < 52) _checkCapture(newPos);
      _afterMove();
    }
  }

  void _checkCapture(int pathPos) {
    if (safeSpots.contains((pathPos + startPositions[currentPlayer]) % 52)) return;
    if (pathPos >= 52) return;

    int myAbsolutePos = (pathPos + startPositions[currentPlayer]) % 52;

    for (int p = 0; p < 4; p++) {
      if (p == currentPlayer) continue;
      for (int i = 0; i < 4; i++) {
        int otherPos = pieces[p][i];
        if (otherPos >= 0 && otherPos < 52) {
          int otherAbsolute = (otherPos + startPositions[p]) % 52;
          if (otherAbsolute == myAbsolutePos) {
            SoundService.playSuccess();
            setState(() => pieces[p][i] = -1);
          }
        }
      }
    }
  }

  void _afterMove() {
    if (pieces[currentPlayer].every((p) => p >= 57)) {
      SoundService.playLevelComplete();
      _showWinDialog();
      return;
    }
    if (diceValue == 6) {
      setState(() => canRoll = true);
    } else {
      _nextPlayer();
    }
  }

  void _nextPlayer() {
    if (numPlayers == null) return;
    // For 2 players: Red (0) and Yellow (2) - opposite corners
    if (numPlayers == 2) {
      currentPlayer = currentPlayer == 0 ? 2 : 0;
    } else {
      currentPlayer = (currentPlayer + 1) % 4;
    }
    setState(() => canRoll = true);
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('${getPlayerName(currentPlayer)} Wins! 🎉', style: TextStyle(color: getPlayerColor(currentPlayer), fontSize: 24)),
        content: AppIcons.trophy(size: 60, color: Colors.amber),
        actions: [TextButton(onPressed: () { Navigator.pop(context); _resetGame(); }, child: const Text('Play Again'))],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      pieces = [[-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1]];
      currentPlayer = 0;
      diceValue = 1;
      canRoll = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (numPlayers == null) return _buildPlayerSelection();
    return _buildGameScreen();
  }

  Widget _buildPlayerSelection() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: AppIcons.back(), onPressed: () => Navigator.pop(context)),
        title: const Text('Ludo', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎲', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            const Text('Select Players', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _playerButton(2, '2 Players', 'Red vs Yellow'),
                const SizedBox(width: 20),
                _playerButton(4, '4 Players', 'All corners'),
              ],
            ),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.ludo),
              icon: AppIcons.help(),
              label: const Text('How to Play?', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerButton(int count, String title, String desc) {
    return GestureDetector(
      onTap: () => _startGame(count),
      child: Container(
        width: 130, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          count == 2 ? AppIcons.people(size: 40, color: const Color(0xFFFF8C42)) : AppIcons.groups(size: 40, color: const Color(0xFFFF8C42)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
          Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildGameScreen() {
    if (numPlayers == 2) return _build2PlayerLayout();
    return _build4PlayerLayout();
  }

  // 2-player: top and bottom (face-to-face)
  Widget _build2PlayerLayout() {
    // Red (0) at bottom, Yellow (2) at top
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // YELLOW (Top - rotated 180°)
            Expanded(
              flex: 1,
              child: Transform.rotate(
                angle: 3.14159,
                child: _buildPlayerPanel(2),
              ),
            ),
            // BOARD
            Expanded(
              flex: 4,
              child: _buildBoardWidget(),
            ),
            // RED (Bottom - normal)
            Expanded(
              flex: 1,
              child: _buildPlayerPanel(0, showNav: true),
            ),
          ],
        ),
      ),
    );
  }

  // 4-player: corners layout
  Widget _build4PlayerLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top row: Red (top-left), Green (top-right)
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: Transform.rotate(angle: 1.5708, child: _buildCornerPanel(0))), // 90° CW
                  Expanded(child: Transform.rotate(angle: -1.5708, child: _buildCornerPanel(1))), // 90° CCW
                ],
              ),
            ),
            // BOARD
            Expanded(
              flex: 3,
              child: _buildBoardWidget(),
            ),
            // Bottom row: Blue (bottom-left), Yellow (bottom-right)
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: Transform.rotate(angle: 1.5708, child: _buildCornerPanel(3))), // 90° CW
                  Expanded(child: Transform.rotate(angle: -1.5708, child: _buildCornerPanel(2))), // 90° CCW
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPanel(int playerIdx, {bool showNav = false}) {
    bool isActive = currentPlayer == playerIdx;
    Color color = getPlayerColor(playerIdx);
    String name = getPlayerName(playerIdx);

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
                IconButton(icon: AppIcons.refresh(size: 20), onPressed: () => _startGame(numPlayers!)),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? color : color.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8)] : [],
                ),
                child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (isActive) ...[
                const SizedBox(width: 10),
                Text(canRoll ? 'Tap Dice!' : 'Move piece!', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: canRoll ? _rollDice : null,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: canRoll ? Colors.white : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 2),
                      boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 8)],
                    ),
                    child: Center(child: Text(isRolling ? '🎲' : '$diceValue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCornerPanel(int playerIdx) {
    bool isActive = currentPlayer == playerIdx;
    Color color = getPlayerColor(playerIdx);
    String name = getPlayerName(playerIdx);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? color : color.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          if (isActive) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: canRoll ? _rollDice : null,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: canRoll ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(child: Text(isRolling ? '🎲' : '$diceValue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoardWidget() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(8),
          child: LayoutBuilder(builder: (context, constraints) {
            double cellSize = constraints.biggest.width / 15;
            return Stack(children: [
              CustomPaint(size: constraints.biggest, painter: LudoBoardPainter()),
              ..._buildAllPieces(cellSize),
            ]);
          }),
        ),
      ),
    );
  }

  List<Widget> _buildAllPieces(double cellSize) {
    List<Widget> widgets = [];
    for (int player = 0; player < 4; player++) {
      for (int i = 0; i < 4; i++) {
        int pos = pieces[player][i];
        Offset? gridPos = pos == -1 ? homePositions[player][i] : getPiecePosition(player, pos);

        if (gridPos != null) {
          bool canTap = player == currentPlayer && !canRoll && ((pos == -1 && diceValue == 6) || (pos >= 0 && pos + diceValue <= 57));
          widgets.add(Positioned(
            left: gridPos.dx * cellSize, top: gridPos.dy * cellSize,
            child: GestureDetector(
              onTap: canTap ? () => _movePiece(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: cellSize * 0.8, height: cellSize * 0.8,
                decoration: BoxDecoration(
                  color: getPlayerColor(player), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: getPlayerColor(player).withAlpha(canTap ? 200 : 100), blurRadius: canTap ? 10 : 5)],
                ),
                child: canTap ? AppIcons.svg('hand-tap', size: 16, color: Colors.white) : null,
              ),
            ),
          ));
        }
      }
    }
    return widgets;
  }
}

class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double cs = size.width / 15;
    Paint r = Paint()..color = const Color(0xFFE53935);
    Paint g = Paint()..color = const Color(0xFF43A047);
    Paint b = Paint()..color = const Color(0xFF1E88E5);
    Paint y = Paint()..color = const Color(0xFFFDD835);
    Paint w = Paint()..color = Colors.white;
    Paint line = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1;

    // Corners: Red(TL), Green(TR), Blue(BL), Yellow(BR)
    canvas.drawRect(Rect.fromLTWH(0, 0, 6*cs, 6*cs), r);
    canvas.drawRect(Rect.fromLTWH(cs, cs, 4*cs, 4*cs), w);
    canvas.drawRect(Rect.fromLTWH(9*cs, 0, 6*cs, 6*cs), g);
    canvas.drawRect(Rect.fromLTWH(10*cs, cs, 4*cs, 4*cs), w);
    canvas.drawRect(Rect.fromLTWH(0, 9*cs, 6*cs, 6*cs), b);
    canvas.drawRect(Rect.fromLTWH(cs, 10*cs, 4*cs, 4*cs), w);
    canvas.drawRect(Rect.fromLTWH(9*cs, 9*cs, 6*cs, 6*cs), y);
    canvas.drawRect(Rect.fromLTWH(10*cs, 10*cs, 4*cs, 4*cs), w);

    _circles(canvas, cs, 1.5, 1.5, r.color);
    _circles(canvas, cs, 10.5, 1.5, g.color);
    _circles(canvas, cs, 1.5, 10.5, b.color);
    _circles(canvas, cs, 10.5, 10.5, y.color);

    // Path cells
    for (int row = 0; row < 6; row++) for (int col = 6; col < 9; col++) { canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), w); canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), line); }
    for (int row = 9; row < 15; row++) for (int col = 6; col < 9; col++) { canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), w); canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), line); }
    for (int row = 6; row < 9; row++) for (int col = 0; col < 6; col++) { canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), w); canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), line); }
    for (int row = 6; row < 9; row++) for (int col = 9; col < 15; col++) { canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), w); canvas.drawRect(Rect.fromLTWH(col*cs, row*cs, cs, cs), line); }

    // Home lanes
    for (int c = 1; c < 6; c++) canvas.drawRect(Rect.fromLTWH(c*cs, 7*cs, cs, cs), r);
    for (int ro = 1; ro < 6; ro++) canvas.drawRect(Rect.fromLTWH(7*cs, ro*cs, cs, cs), g);
    for (int c = 9; c < 14; c++) canvas.drawRect(Rect.fromLTWH(c*cs, 7*cs, cs, cs), y);
    for (int ro = 9; ro < 14; ro++) canvas.drawRect(Rect.fromLTWH(7*cs, ro*cs, cs, cs), b);

    // Center triangles
    double cx = 7.5*cs, cy = 7.5*cs;
    canvas.drawPath(Path()..moveTo(6*cs, 6*cs)..lineTo(cx, cy)..lineTo(6*cs, 9*cs)..close(), r);
    canvas.drawPath(Path()..moveTo(6*cs, 6*cs)..lineTo(cx, cy)..lineTo(9*cs, 6*cs)..close(), g);
    canvas.drawPath(Path()..moveTo(9*cs, 6*cs)..lineTo(cx, cy)..lineTo(9*cs, 9*cs)..close(), y);
    canvas.drawPath(Path()..moveTo(6*cs, 9*cs)..lineTo(cx, cy)..lineTo(9*cs, 9*cs)..close(), b);

    // Stars - on WHITE path cells only!
    TextPainter star = TextPainter(text: const TextSpan(text: '★', style: TextStyle(fontSize: 20, color: Colors.black)), textDirection: TextDirection.ltr);
    star.layout();
    // 8 stars total on white path cells:
    // - 4 start positions (just outside each corner)
    // - 4 safe spots (around the middle of each side)
    List<Offset> starPositions = [
      Offset(1, 6),   // Red START - left side, row 6
      Offset(2, 8),   // Safe spot - left side, row 8
      Offset(6, 2),   // Safe spot - top, col 6
      Offset(8, 1),   // Green START - top, col 8
      Offset(12, 6),  // Safe spot - right side, row 6
      Offset(13, 8),  // Yellow START - right side, row 8
      Offset(8, 12),  // Safe spot - bottom, col 8
      Offset(6, 13),  // Blue START - bottom, col 6
    ];
    for (var p in starPositions) {
      star.paint(canvas, Offset(p.dx*cs + cs*0.25, p.dy*cs + cs*0.15));
    }
  }

  void _circles(Canvas canvas, double cs, double sx, double sy, Color c) {
    Paint p = Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 3;
    for (var o in [Offset(0,0), Offset(2,0), Offset(0,2), Offset(2,2)]) {
      canvas.drawCircle(Offset((sx+o.dx+0.4)*cs, (sy+o.dy+0.4)*cs), cs*0.35, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
