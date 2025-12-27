import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

// Candy types
enum CandyType { red, orange, yellow, green, blue, purple }

// Special candy types
enum SpecialType { none, stripedH, stripedV, wrapped, colorBomb }

const List<Color> candyColors = [
  Color(0xFFFF4757), // Red
  Color(0xFFFF6B35), // Orange
  Color(0xFFFFD93D), // Yellow
  Color(0xFF6BCB77), // Green
  Color(0xFF4D96FF), // Blue
  Color(0xFFA66CFF), // Purple
];

class Candy {
  final String id;
  CandyType type;
  SpecialType special;
  bool isMatched;
  bool isNew;
  double offsetY; // For falling animation

  Candy({
    required this.type,
    this.special = SpecialType.none,
    this.isMatched = false,
    this.isNew = false,
    this.offsetY = 0,
    String? id,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(10000)}';

  Color get color => candyColors[type.index];
  
  Candy copy() => Candy(
    type: type,
    special: special,
    isMatched: isMatched,
    isNew: isNew,
    offsetY: offsetY,
    id: id,
  );
}

class CandyCrushScreen extends StatefulWidget {
  const CandyCrushScreen({super.key});

  @override
  State<CandyCrushScreen> createState() => _CandyCrushScreenState();
}

class _CandyCrushScreenState extends State<CandyCrushScreen> with TickerProviderStateMixin {
  // Game constants
  static const int gridWidth = 8;
  static const int gridHeight = 8;
  static const Color cream = Color(0xFFFFFBF5);

  // Game state
  List<List<Candy?>> grid = [];
  int? selectedRow;
  int? selectedCol;
  
  int score = 0;
  int moves = 30;
  int targetScore = 5000;
  int level = 1;
  int combo = 0;
  
  // Power boosters
  int hammers = 3;      // Destroy single candy
  int shuffles = 2;     // Shuffle board
  int freeSwitches = 2; // Swap any two candies
  bool hammerMode = false;
  bool freeSwitchMode = false;
  int? firstSwitchRow;
  int? firstSwitchCol;
  
  bool isAnimating = false;
  bool isGameOver = false;
  bool showStartScreen = true;
  bool levelComplete = false;
  
  final Random _random = Random();
  
  // Animation controllers
  AnimationController? _swapController;
  AnimationController? _fallController;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _swapController?.dispose();
    _fallController?.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      showStartScreen = false;
      score = 0;
      moves = 30 + (level - 1) * 5;
      targetScore = 3000 + (level - 1) * 2000;
      isGameOver = false;
      levelComplete = false;
      combo = 0;
      _initGrid();
    });
  }

  void _initGrid() {
    // First, create empty grid
    grid = List.generate(
      gridHeight,
      (_) => List.filled(gridWidth, null),
    );
    
    // Then fill with candies, checking for matches
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        grid[row][col] = _generateCandy(row, col);
      }
    }
    
    // Keep regenerating until no matches
    int attempts = 0;
    while (_hasMatches() && attempts < 100) {
      for (int row = 0; row < gridHeight; row++) {
        for (int col = 0; col < gridWidth; col++) {
          if (_isPartOfMatch(row, col)) {
            grid[row][col] = Candy(type: CandyType.values[_random.nextInt(CandyType.values.length)]);
          }
        }
      }
      attempts++;
    }
  }

  Candy _generateCandy(int row, int col) {
    // Avoid creating matches during generation
    List<CandyType> available = List.from(CandyType.values);
    
    // Check left (only if those cells exist and are filled)
    if (col >= 2 && 
        grid[row][col - 1] != null && 
        grid[row][col - 2] != null &&
        grid[row][col - 1]!.type == grid[row][col - 2]!.type) {
      available.remove(grid[row][col - 1]!.type);
    }
    
    // Check above (only if those cells exist and are filled)
    if (row >= 2 && 
        grid[row - 1][col] != null && 
        grid[row - 2][col] != null &&
        grid[row - 1][col]!.type == grid[row - 2][col]!.type) {
      available.remove(grid[row - 1][col]!.type);
    }
    
    if (available.isEmpty) {
      available = List.from(CandyType.values);
    }
    
    return Candy(type: available[_random.nextInt(available.length)]);
  }

  bool _hasMatches() {
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        if (_isPartOfMatch(row, col)) return true;
      }
    }
    return false;
  }

  bool _isPartOfMatch(int row, int col) {
    if (grid[row][col] == null) return false;
    final type = grid[row][col]!.type;
    
    // Check horizontal
    int hCount = 1;
    for (int c = col - 1; c >= 0 && grid[row][c]?.type == type; c--) hCount++;
    for (int c = col + 1; c < gridWidth && grid[row][c]?.type == type; c++) hCount++;
    if (hCount >= 3) return true;
    
    // Check vertical
    int vCount = 1;
    for (int r = row - 1; r >= 0 && grid[r][col]?.type == type; r--) vCount++;
    for (int r = row + 1; r < gridHeight && grid[r][col]?.type == type; r++) vCount++;
    if (vCount >= 3) return true;
    
    return false;
  }

  void _onCandyTap(int row, int col) {
    if (isAnimating || isGameOver || levelComplete) return;

    // Handle Power-up Modes
    if (hammerMode) {
      _handleHammer(row, col);
      return;
    }
    
    if (freeSwitchMode) {
      _handleFreeSwitch(row, col);
      return;
    }
    
    if (selectedRow == null) {
      // First selection
      setState(() {
        selectedRow = row;
        selectedCol = col;
      });
    } else {
      // Check if adjacent
      final dr = (row - selectedRow!).abs();
      final dc = (col - selectedCol!).abs();
      
      if ((dr == 1 && dc == 0) || (dr == 0 && dc == 1)) {
        // Adjacent - try swap
        _trySwap(selectedRow!, selectedCol!, row, col);
      }
      
      setState(() {
        selectedRow = null;
        selectedCol = null;
      });
    }
  }

  void _handleHammer(int row, int col) async {
    if (grid[row][col] == null) return;
    
    setState(() {
      grid[row][col] = null; // Destroy candy
      hammerMode = false;
      hammers--;
      isAnimating = true; // Block input while falling
    });
    
    SoundService.playSuccess();
    
    // Trigger fall and fill
    await Future.delayed(const Duration(milliseconds: 300));
    await _dropCandies();
    await _fillEmptySpaces();
    
    // Check for matches that might have occurred after drop
    await _processMatches();
    
    setState(() {
      isAnimating = false;
    });
  }

  void _handleFreeSwitch(int row, int col) {
    if (firstSwitchRow == null) {
      setState(() {
        firstSwitchRow = row;
        firstSwitchCol = col;
      });
    } else {
      // Second selection
      final r1 = firstSwitchRow!;
      final c1 = firstSwitchCol!;
      
      // Perform swap provided they are distinct
      if (r1 != row || c1 != col) {
        _performFreeSwitch(r1, c1, row, col);
      }
      
      setState(() {
        firstSwitchRow = null;
        firstSwitchCol = null;
        freeSwitchMode = false;
        freeSwitches--;
      });
    }
  }

  Future<void> _performFreeSwitch(int r1, int c1, int r2, int c2) async {
    isAnimating = true;
    
    // Animate Swap
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;
    
    SoundService.playTap();
    setState(() {});
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check matches
    if (_hasMatches()) {
       await _processMatches();
    }
    
    isAnimating = false;
    setState(() {});
  }

  void _activateHammer() {
    if (hammers > 0 && !isAnimating) {
      setState(() {
        hammerMode = !hammerMode;
        freeSwitchMode = false;
        selectedRow = null;
        selectedCol = null;
        firstSwitchRow = null;
      });
    }
  }

  void _activateShuffle() {
    if (shuffles > 0 && !isAnimating) {
      setState(() {
        shuffles--;
        _shuffleBoard();
      });
      SoundService.playSuccess();
    }
  }

  void _shuffleBoard() {
    List<Candy?> allCandies = [];
    for (var row in grid) {
      for (var candy in row) {
        if (candy != null) allCandies.add(candy);
      }
    }
    
    allCandies.shuffle();
    
    int index = 0;
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        if (grid[row][col] != null) {
          grid[row][col] = allCandies[index++];
        }
      }
    }
    
    // Check if shuffle created matches
    if (_hasMatches()) {
       _processMatches();
    }
  }

  void _activateFreeSwitch() {
    if (freeSwitches > 0 && !isAnimating) {
      setState(() {
        freeSwitchMode = !freeSwitchMode;
        hammerMode = false;
        selectedRow = null;
        selectedCol = null;
        firstSwitchRow = null;
      });
    }
  }

  void _onCandyDrag(int fromRow, int fromCol, DragUpdateDetails details) {
    if (isAnimating || isGameOver || levelComplete) return;
    
    const threshold = 30.0;
    int toRow = fromRow;
    int toCol = fromCol;
    
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      // Horizontal
      if (details.delta.dx > threshold) toCol++;
      else if (details.delta.dx < -threshold) toCol--;
    } else {
      // Vertical
      if (details.delta.dy > threshold) toRow++;
      else if (details.delta.dy < -threshold) toRow--;
    }
    
    if (toRow >= 0 && toRow < gridHeight && toCol >= 0 && toCol < gridWidth &&
        (toRow != fromRow || toCol != fromCol)) {
      _trySwap(fromRow, fromCol, toRow, toCol);
    }
  }

  Future<void> _trySwap(int r1, int c1, int r2, int c2) async {
    if (isAnimating) return;
    isAnimating = true;
    
    // Swap
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;
    setState(() {});
    
    setState(() {});
    
    // Slow down swap for visual clarity
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if valid
    if (_hasMatches() || 
        grid[r1][c1]?.special == SpecialType.colorBomb ||
        grid[r2][c2]?.special == SpecialType.colorBomb) {
      // Valid swap
      moves--;
      combo = 0;
      await _processMatches();
      
      // Check game state
      if (score >= targetScore) {
        setState(() => levelComplete = true);
        SoundService.playSuccess();
      } else if (moves <= 0) {
        setState(() => isGameOver = true);
        SoundService.playFail();
      }
    } else {
      // Invalid - swap back
      final temp2 = grid[r1][c1];
      grid[r1][c1] = grid[r2][c2];
      grid[r2][c2] = temp2;
      SoundService.playFail();
    }
    
    setState(() {});
    isAnimating = false;
  }

  Future<void> _processMatches() async {
    bool hasMatch = true;
    
    while (hasMatch) {
      hasMatch = false;
      
      // Find all matches
      List<List<bool>> matched = List.generate(
        gridHeight, 
        (_) => List.filled(gridWidth, false),
      );
      
      // Check horizontal matches
      for (int row = 0; row < gridHeight; row++) {
        for (int col = 0; col < gridWidth - 2; col++) {
          if (grid[row][col] != null) {
            final type = grid[row][col]!.type;
            int count = 1;
            while (col + count < gridWidth && grid[row][col + count]?.type == type) {
              count++;
            }
            if (count >= 3) {
              hasMatch = true;
              for (int i = 0; i < count; i++) {
                matched[row][col + i] = true;
              }
              // Create special candy
              if (count == 4) {
                grid[row][col + 1]!.special = SpecialType.stripedH;
                matched[row][col + 1] = false;
              } else if (count >= 5) {
                grid[row][col + 2]!.special = SpecialType.colorBomb;
                matched[row][col + 2] = false;
              }
              col += count - 1;
            }
          }
        }
      }
      
      // Check vertical matches
      for (int col = 0; col < gridWidth; col++) {
        for (int row = 0; row < gridHeight - 2; row++) {
          if (grid[row][col] != null) {
            final type = grid[row][col]!.type;
            int count = 1;
            while (row + count < gridHeight && grid[row + count][col]?.type == type) {
              count++;
            }
            if (count >= 3) {
              hasMatch = true;
              for (int i = 0; i < count; i++) {
                matched[row + i][col] = true;
              }
              // Create special candy
              if (count == 4) {
                grid[row + 1][col]!.special = SpecialType.stripedV;
                matched[row + 1][col] = false;
              } else if (count >= 5) {
                grid[row + 2][col]!.special = SpecialType.colorBomb;
                matched[row + 2][col] = false;
              }
              row += count - 1;
            }
          }
        }
      }
      
      // Check for L/T shapes (wrapped candy)
      for (int row = 0; row < gridHeight; row++) {
        for (int col = 0; col < gridWidth; col++) {
          if (matched[row][col] && _isLorTShape(row, col, matched)) {
            grid[row][col]!.special = SpecialType.wrapped;
            matched[row][col] = false;
          }
        }
      }
      
      if (hasMatch) {
        combo++;
        
        // Handle special candy explosions
        for (int row = 0; row < gridHeight; row++) {
          for (int col = 0; col < gridWidth; col++) {
            if (matched[row][col] && grid[row][col]?.special != SpecialType.none) {
              _triggerSpecial(row, col, matched);
            }
          }
        }
        
        // Calculate score
        int matchCount = 0;
        for (int row = 0; row < gridHeight; row++) {
          for (int col = 0; col < gridWidth; col++) {
            if (matched[row][col]) matchCount++;
          }
        }
        score += matchCount * 10 * (combo > 1 ? combo : 1);
        
        // Mark matched candies for animation
        for (int row = 0; row < gridHeight; row++) {
          for (int col = 0; col < gridWidth; col++) {
            if (matched[row][col] && grid[row][col] != null) {
              grid[row][col]!.isMatched = true;
            }
          }
        }
        
        setState(() {});
        SoundService.playTap();
        
        // Wait for vanishing animation
        await Future.delayed(const Duration(milliseconds: 250));
        
        // Remove matched candies
        for (int row = 0; row < gridHeight; row++) {
          for (int col = 0; col < gridWidth; col++) {
            if (matched[row][col]) {
              grid[row][col] = null;
            }
          }
        }
        
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 100)); // Short pause before drop
        
        // Drop candies
        await _dropCandies();
        
        // Fill empty spaces
        await _fillEmptySpaces();
        
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 300)); // Wait for drop animation
      }
    }
  }

  bool _isLorTShape(int row, int col, List<List<bool>> matched) {
    // Check if this position is part of an L or T shape
    int horizontal = 0;
    int vertical = 0;
    
    for (int c = col - 1; c >= 0 && matched[row][c]; c--) horizontal++;
    for (int c = col + 1; c < gridWidth && matched[row][c]; c++) horizontal++;
    for (int r = row - 1; r >= 0 && matched[r][col]; r--) vertical++;
    for (int r = row + 1; r < gridHeight && matched[r][col]; r++) vertical++;
    
    return horizontal >= 2 && vertical >= 2;
  }

  void _triggerSpecial(int row, int col, List<List<bool>> matched) {
    final special = grid[row][col]!.special;
    
    switch (special) {
      case SpecialType.stripedH:
        for (int c = 0; c < gridWidth; c++) matched[row][c] = true;
        break;
      case SpecialType.stripedV:
        for (int r = 0; r < gridHeight; r++) matched[r][col] = true;
        break;
      case SpecialType.wrapped:
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final r = row + dr;
            final c = col + dc;
            if (r >= 0 && r < gridHeight && c >= 0 && c < gridWidth) {
              matched[r][c] = true;
            }
          }
        }
        break;
      case SpecialType.colorBomb:
        final targetType = _getMostCommonType();
        for (int r = 0; r < gridHeight; r++) {
          for (int c = 0; c < gridWidth; c++) {
            if (grid[r][c]?.type == targetType) matched[r][c] = true;
          }
        }
        break;
      case SpecialType.none:
        break;
    }
  }

  CandyType _getMostCommonType() {
    Map<CandyType, int> counts = {};
    for (var row in grid) {
      for (var candy in row) {
        if (candy != null) {
          counts[candy.type] = (counts[candy.type] ?? 0) + 1;
        }
      }
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<void> _dropCandies() async {
    for (int col = 0; col < gridWidth; col++) {
      int emptyRow = gridHeight - 1;
      for (int row = gridHeight - 1; row >= 0; row--) {
        if (grid[row][col] != null) {
          if (row != emptyRow) {
            grid[emptyRow][col] = grid[row][col];
            grid[row][col] = null;
          }
          emptyRow--;
        }
      }
    }
    setState(() {});
  }

  Future<void> _fillEmptySpaces() async {
    for (int col = 0; col < gridWidth; col++) {
      for (int row = 0; row < gridHeight; row++) {
        if (grid[row][col] == null) {
          grid[row][col] = Candy(
            type: CandyType.values[_random.nextInt(CandyType.values.length)],
            isNew: true,
          );
        }
      }
    }
  }

  void _nextLevel() {
    level++;
    _startGame();
  }

  void _restartLevel() {
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    if (showStartScreen) return _buildStartScreen();
    
    // Initialize grid if empty
    if (grid.isEmpty) {
      _initGrid();
    }
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 5),
                  _buildScoreBar(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildGameBoard()),
                  const SizedBox(height: 10),
                  _buildControlBar(),
                ],
              ),
              if (isGameOver || levelComplete) _buildOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _showBoosterSheet,
            icon: const Icon(Icons.flash_on, color: Colors.white),
            label: const Text('BOOSTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  void _showBoosterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF6A1B9A), // Deep purple like reference
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text('POWER UPS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBoosterBtn('🔨', 'Smash', hammers, hammerMode, () { Navigator.pop(context); _activateHammer(); }),
                _buildBoosterBtn('🔀', 'Shuffle', shuffles, false, () { Navigator.pop(context); _activateShuffle(); }),
                _buildBoosterBtn('✋', 'Swap', freeSwitches, freeSwitchMode, () { Navigator.pop(context); _activateFreeSwitch(); }),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
              // Candy icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: candyColors.map((c) => Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: c.withAlpha(150), blurRadius: 10)],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 25),
              const Text(
                'CANDY CRUSH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Match-3 Puzzle',
                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcons.svg('play', size: 24, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text('PLAY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => showHowToPlay(context, GameRules.candyCrush),
                icon: AppIcons.help(color: Colors.white70),
                label: const Text('How to Play?', style: TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '🍬 Swap candies to match 3+ of same color 🍬',
                  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: AppIcons.back(color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          /* ... Level and Moves code remains same or similar ... */
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Level $level', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⚡ ', style: TextStyle(fontSize: 14)), // Changed icon to bolt for moves/energy
                 Text('$moves', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBoosterBtn(String emoji, String label, int count, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber : Colors.white.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(100), width: 2),
              boxShadow: isActive ? [BoxShadow(color: Colors.amber.withAlpha(150), blurRadius: 10)] : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    final progress = (score / targetScore).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text('Target: $targetScore', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.green : Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          (constraints.maxWidth - 20) / gridWidth,
          (constraints.maxHeight - 20) / gridHeight,
        );
        final boardWidth = cellSize * gridWidth;
        final boardHeight = cellSize * gridHeight;
        
        // Flatten grid to widgets with coordinates
        List<Widget> candyWidgets = [];
        
        // 1. Add Background Grid Cells
        for(int r=0; r<gridHeight; r++) {
          for(int c=0; c<gridWidth; c++) {
            candyWidgets.add(
              Positioned(
                top: r * cellSize,
                left: c * cellSize,
                width: cellSize,
                height: cellSize,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              )
            );
          }
        }

        // 2. Add Moving Candies
        for(int r=0; r<gridHeight; r++) {
          for(int c=0; c<gridWidth; c++) {
            final candy = grid[r][c];
            if (candy != null) {
              candyWidgets.add(
                AnimatedPositioned(
                  key: ValueKey(candy.id), // KEY IS CRITICAL FOR MOVEMENT ANIMATION
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  top: r * cellSize,
                  left: c * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: _buildCandyCellContent(candy, r, c),
                )
              );
            }
          }
        }
        
        return Center(
          child: Container(
            width: boardWidth + 10,
            height: boardHeight + 10,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(40), width: 3),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2)],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: candyWidgets,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCandyCellContent(Candy candy, int row, int col) {
    final isSelected = selectedRow == row && selectedCol == col;
    final isTargeted = (hammerMode || freeSwitchMode) && !isAnimating;
    final isSwitchSelection = freeSwitchMode && firstSwitchRow == row && firstSwitchCol == col;
    
    return GestureDetector(
      onTap: () => _onCandyTap(row, col),
      onPanUpdate: (details) => _onCandyDrag(row, col, details),
      child: AnimatedScale(
        scale: candy.isMatched ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: candy.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
            border: (isSelected || isSwitchSelection)
              ? Border.all(color: Colors.white, width: 3)
              : null,
            boxShadow: [
              BoxShadow(
                color: candy.color.withAlpha(100),
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.white30,
                blurRadius: 2,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: _buildCandyDecoration(candy),
        ),
      ),
    );
  }



  Widget _buildCandyDecoration(Candy candy) {
    Widget? specialIcon;
    
    switch (candy.special) {
      case SpecialType.stripedH:
        specialIcon = const Icon(Icons.horizontal_rule, color: Colors.white, size: 18);
        break;
      case SpecialType.stripedV:
        specialIcon = const RotatedBox(
          quarterTurns: 1,
          child: Icon(Icons.horizontal_rule, color: Colors.white, size: 18),
        );
        break;
      case SpecialType.wrapped:
        specialIcon = const Icon(Icons.star, color: Colors.white, size: 16);
        break;
      case SpecialType.colorBomb:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue],
            ),
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.all(4),
        );
      case SpecialType.none:
        break;
    }
    
    return Stack(
      children: [
        // Shine effect
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              shape: BoxShape.circle,
            ),
          ),
        ),
        if (specialIcon != null)
          Center(child: specialIcon),
      ],
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  levelComplete ? '🎉 Level Complete!' : '💔 Game Over',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: levelComplete ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 15),
                Text('Score: $score', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: levelComplete ? _nextLevel : _restartLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: levelComplete ? Colors.green : Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        levelComplete ? 'Next Level' : 'Try Again',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
