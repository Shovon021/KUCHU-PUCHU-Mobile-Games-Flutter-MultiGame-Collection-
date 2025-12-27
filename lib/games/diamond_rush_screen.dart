import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

// Spider class for enemies
class Spider {
  int x;
  int y;
  int dx;
  Spider(this.x, this.y, this.dx);
}

class DiamondRushScreen extends StatefulWidget {
  const DiamondRushScreen({super.key});

  @override
  State<DiamondRushScreen> createState() => _DiamondRushScreenState();
}

class _DiamondRushScreenState extends State<DiamondRushScreen> {
  // Tile types
  static const int empty = 0;
  static const int wall = 1;
  static const int diamond = 2;
  static const int boulder = 3;
  static const int spike = 4;
  static const int exitTile = 5;
  static const int sand = 6;
  static const int fire = 8;
  static const int spiderTile = 9;
  static const int breakableWall = 10;
  static const int keyTile = 11;
  static const int lockedDoor = 12;

  // Colors
  static const Color bgDark = Color(0xFF0f0f23);
  static const Color bgMedium = Color(0xFF1a1a3e);
  static const Color wallColor = Color(0xFF4a4a6a);
  static const Color sandColor = Color(0xFFC4A35A);
  static const Color diamondColor = Color(0xFF00D9FF);

  // Game state
  int playerX = 1;
  int playerY = 1;
  int diamonds = 0;
  int totalDiamonds = 0;
  int currentLevel = 1;
  int totalLevels = 8;
  bool gameStarted = false;
  bool levelComplete = false;
  bool isDead = false;
  bool hasKey = false;
  List<List<int>> grid = [];
  List<List<int>> originalGrid = [];
  
  // Spiders as separate class instances
  List<Spider> spiders = <Spider>[];
  List<Spider> originalSpiders = <Spider>[];
  
  Timer? gameTimer;
  Timer? fireTimer;
  bool fireActive = true;

  @override
  void dispose() {
    gameTimer?.cancel();
    fireTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      currentLevel = 1;
    });
    _loadLevel(currentLevel);
  }

  void _loadLevel(int level) {
    gameTimer?.cancel();
    fireTimer?.cancel();
    spiders = <Spider>[];
    
    switch (level) {
      case 1: _loadLevel1(); break;
      case 2: _loadLevel2(); break;
      case 3: _loadLevel3(); break;
      case 4: _loadLevel4(); break;
      case 5: _loadLevel5(); break;
      case 6: _loadLevel6(); break;
      case 7: _loadLevel7(); break;
      case 8: _loadLevel8(); break;
    }

    // Count diamonds and extract spiders
    totalDiamonds = 0;
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] == diamond) totalDiamonds++;
        if (grid[y][x] == spiderTile) {
          spiders.add(Spider(x, y, 1));
          grid[y][x] = empty;
        }
      }
    }

    originalGrid = grid.map((row) => List<int>.from(row)).toList();
    originalSpiders = spiders.map((s) => Spider(s.x, s.y, s.dx)).toList();

    setState(() {
      diamonds = 0;
      hasKey = false;
      levelComplete = false;
      isDead = false;
    });

    // Game loop for gravity and spiders
    gameTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!isDead && !levelComplete && mounted) {
        _moveSpiders();
        _applyGravity();
        setState(() {});
      }
    });
    
    fireTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => fireActive = !fireActive);
    });
  }

  void _moveSpiders() {
    for (int i = 0; i < spiders.length; i++) {
      Spider spider = spiders[i];
      int newX = spider.x + spider.dx;
      
      if (newX >= 0 && newX < grid[0].length && grid[spider.y][newX] == empty) {
        spider.x = newX;
      } else {
        spider.dx = -spider.dx;
      }
      
      // Check player collision
      if (spider.x == playerX && spider.y == playerY) {
        _onDeath();
        return;
      }
    }
  }

  void _applyGravity() {
    for (int y = grid.length - 2; y >= 0; y--) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] == boulder) {
          int below = y + 1;
          
          if (below < grid.length && grid[below][x] == empty) {
            grid[below][x] = boulder;
            grid[y][x] = empty;
            
            if (playerX == x && playerY == below) {
              _onDeath();
              return;
            }
          }
          else if (below < grid.length && (grid[below][x] == boulder || grid[below][x] == diamond)) {
            if (x > 0 && grid[y][x-1] == empty && grid[below][x-1] == empty) {
              grid[y][x] = empty;
              grid[y][x-1] = boulder;
            }
            else if (x < grid[y].length - 1 && grid[y][x+1] == empty && grid[below][x+1] == empty) {
              grid[y][x] = empty;
              grid[y][x+1] = boulder;
            }
          }
        }
      }
    }
  }

  void _restartLevel() {
    HapticFeedback.mediumImpact();
    grid = originalGrid.map((row) => List<int>.from(row)).toList();
    spiders = originalSpiders.map((s) => Spider(s.x, s.y, s.dx)).toList();
    _findPlayerStart();
    setState(() {
      diamonds = 0;
      hasKey = false;
      isDead = false;
      levelComplete = false;
    });
  }

  void _findPlayerStart() {
    playerX = 1;
    playerY = 1;
  }

  void _loadLevel1() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 6, 6, 2, 6, 6, 0, 0, 1],
      [1, 0, 6, 6, 6, 6, 2, 6, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 6, 6, 6, 6, 6, 6, 0, 1],
      [1, 0, 6, 2, 6, 6, 6, 6, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 3;
  }

  void _loadLevel2() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 3, 0, 0, 3, 0, 2, 0, 1],
      [1, 0, 6, 0, 0, 6, 0, 0, 0, 1],
      [1, 0, 6, 0, 0, 6, 2, 0, 0, 1],
      [1, 0, 6, 2, 0, 6, 6, 6, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 5;
  }

  void _loadLevel3() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 3, 0, 2, 0, 3, 0, 2, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 0, 4, 4, 0, 4, 4, 0, 0, 1],
      [1, 0, 2, 0, 0, 0, 0, 0, 2, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 1;
  }

  // Level 4: Spiders!
  void _loadLevel4() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 6, 2, 6, 0, 0, 2, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0, 9, 0, 1],
      [1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1],
      [1, 0, 9, 0, 0, 0, 0, 0, 2, 0, 1],
      [1, 2, 0, 0, 6, 6, 6, 0, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 1;
  }

  void _loadLevel5() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 8, 0, 0, 0, 2, 0, 1],
      [1, 0, 6, 2, 0, 0, 8, 0, 0, 0, 1],
      [1, 0, 6, 6, 0, 0, 0, 0, 6, 0, 1],
      [1, 0, 0, 0, 8, 0, 2, 0, 6, 0, 1],
      [1, 0, 2, 0, 0, 0, 0, 0, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 5;
  }

  void _loadLevel6() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 6, 2, 6, 1, 0, 0, 2, 0, 1],
      [1, 0, 6, 6,11, 1, 0, 3, 0, 0, 1],
      [1, 0, 0, 0, 0,12, 0, 0, 0, 0, 1],
      [1, 0, 6, 2, 6, 1, 0, 0, 2, 0, 1],
      [1, 0, 0, 0, 0, 1, 0, 0, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 3;
  }

  void _loadLevel7() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0,10, 0, 2, 0,10, 0, 0, 0, 0, 1],
      [1, 0, 6, 3, 6, 6, 6, 0, 3, 0, 0, 1],
      [1, 0, 6, 6, 6,10, 6, 0, 6, 0, 0, 1],
      [1, 0, 0, 0, 2, 0, 0, 0, 6, 2, 0, 1],
      [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 1;
  }

  // Level 8: Final with spiders
  void _loadLevel8() {
    grid = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 3, 0, 2, 0, 1, 0, 0, 9, 0, 1],
      [1, 0, 6, 0, 6, 8, 1, 0, 2, 0, 0, 1],
      [1, 0, 6, 2, 6, 0,12, 0, 0, 0, 0, 1],
      [1, 4, 0, 0, 0, 0, 1, 0, 3, 0, 2, 1],
      [1, 2,11, 0, 0, 0, 1, 0, 6, 0, 5, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ];
    playerX = 1; playerY = 1;
  }

  void _move(int dx, int dy) {
    if (isDead || levelComplete) return;

    int newX = playerX + dx;
    int newY = playerY + dy;

    if (newY < 0 || newY >= grid.length || newX < 0 || newX >= grid[0].length) return;

    int target = grid[newY][newX];

    if (target == wall) return;

    if (target == lockedDoor) {
      if (hasKey) {
        grid[newY][newX] = empty;
        hasKey = false;
        HapticFeedback.mediumImpact();
      }
      return;
    }

    if (target == boulder && dy == 0) {
      int pushX = newX + dx;
      if (pushX >= 0 && pushX < grid[0].length) {
        int pushTarget = grid[newY][pushX];
        if (pushTarget == empty || pushTarget == spike) {
          grid[newY][pushX] = boulder;
          grid[newY][newX] = empty;
          HapticFeedback.lightImpact();
        } else {
          return;
        }
      } else {
        return;
      }
    } else if (target == boulder) {
      return;
    }

    if (target == sand) {
      grid[newY][newX] = empty;
      HapticFeedback.selectionClick();
    }

    if (target == breakableWall) {
      grid[newY][newX] = empty;
      HapticFeedback.mediumImpact();
    }

    if (target == diamond) {
      SoundService.playCoin();
      diamonds++;
      grid[newY][newX] = empty;
      HapticFeedback.selectionClick();
    }

    if (target == keyTile) {
      hasKey = true;
      grid[newY][newX] = empty;
      HapticFeedback.mediumImpact();
    }

    if (target == spike) {
      _onDeath();
      return;
    }

    if (target == fire && fireActive) {
      _onDeath();
      return;
    }

    // Spider collision check
    for (int i = 0; i < spiders.length; i++) {
      if (spiders[i].x == newX && spiders[i].y == newY) {
        _onDeath();
        return;
      }
    }

    if (target == exitTile) {
      if (diamonds >= totalDiamonds) {
        _onLevelComplete();
      }
      return;
    }

    setState(() {
      playerX = newX;
      playerY = newY;
    });
  }

  void _onDeath() {
    SoundService.playGameOver();
    setState(() => isDead = true);
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _restartLevel();
    });
  }

  void _onLevelComplete() {
    SoundService.playLevelComplete();
    setState(() => levelComplete = true);
    HapticFeedback.mediumImpact();
    
    if (currentLevel >= totalLevels) {
      _showVictoryDialog();
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          currentLevel++;
          _loadLevel(currentLevel);
        }
      });
    }
  }

  void _showVictoryDialog() {
    gameTimer?.cancel();
    fireTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: bgMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(children: [
          Text('🏆', style: TextStyle(fontSize: 50)),
          SizedBox(height: 10),
          Text('Victory!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
          Text('All levels completed!', style: TextStyle(color: Colors.white70)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: diamondColor),
            onPressed: () { Navigator.pop(context); _startGame(); },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      backgroundColor: bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [diamondColor, Color(0xFF00A8CC)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: diamondColor.withAlpha(100), blurRadius: 30)],
                  ),
                  child: const Text('💎', style: TextStyle(fontSize: 45)),
                ),
                const SizedBox(height: 25),
                const Text('Diamond Rush', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Classic Puzzle Adventure', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: diamondColor,
                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                  child: const Column(children: [
                    Text('How to Play', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 8),
                    Text('💎 Collect all diamonds', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🟫 Dig through sand', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🪨 Push boulders (they fall!)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🕷️ Avoid spiders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🔥 Time fire traps', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('🔑 Find keys for doors', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: () => showHowToPlay(context, GameRules.diamondRush),
                  icon: AppIcons.help(color: Colors.white54),
                  label: const Text('Bilingual Rules', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: AppIcons.back(size: 22, color: Colors.white), onPressed: () { gameTimer?.cancel(); fireTimer?.cancel(); Navigator.pop(context); }),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                    child: Text('Level $currentLevel/$totalLevels', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: diamondColor, borderRadius: BorderRadius.circular(10)),
                      child: Text('💎 $diamonds/$totalDiamonds', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                    ),
                    if (hasKey) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                        child: const Text('🔑', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _restartLevel,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withAlpha(150), borderRadius: BorderRadius.circular(10)),
                        child: AppIcons.refresh(size: 18, color: Colors.white),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Game grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: grid.isNotEmpty ? grid[0].length / grid.length : 1,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgMedium,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(20), width: 2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (grid.isEmpty) return const SizedBox();
                        double tileSize = constraints.maxWidth / grid[0].length;
                        return Stack(
                          children: [
                            for (int y = 0; y < grid.length; y++)
                              for (int x = 0; x < grid[y].length; x++)
                                Positioned(
                                  left: x * tileSize,
                                  top: y * tileSize,
                                  width: tileSize,
                                  height: tileSize,
                                  child: _buildTile(x, y),
                                ),
                            // Render spiders on top
                            for (int i = 0; i < spiders.length; i++)
                              Positioned(
                                left: spiders[i].x * tileSize,
                                top: spiders[i].y * tileSize,
                                width: tileSize,
                                height: tileSize,
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(color: bgMedium, borderRadius: BorderRadius.circular(3)),
                                  child: const Center(child: Text('🕷️', style: TextStyle(fontSize: 16))),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Status
            if (isDead || levelComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: isDead ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(12)),
                child: Text(isDead ? '💀 Oops! Restarting...' : '✅ Level Complete!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),

            // Controls
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140, height: 140,
                    child: Stack(
                      children: [
                        Positioned(top: 0, left: 45, child: _buildDpadBtn('arrow-up', () => _move(0, -1))),
                        Positioned(bottom: 0, left: 45, child: _buildDpadBtn('arrow-down', () => _move(0, 1))),
                        Positioned(top: 45, left: 0, child: _buildDpadBtn('arrow-left', () => _move(-1, 0))),
                        Positioned(top: 45, right: 0, child: _buildDpadBtn('arrow-right', () => _move(1, 0))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tip:', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text(
                          currentLevel == 1 ? 'Dig sand to move' :
                          currentLevel == 2 ? "Don't stand under boulders!" :
                          currentLevel == 3 ? 'Push boulders onto spikes' :
                          currentLevel == 4 ? 'Watch the spiders!' :
                          currentLevel == 5 ? 'Wait for fire to stop' :
                          currentLevel == 6 ? 'Find key first!' :
                          currentLevel == 7 ? 'Break weak walls' : 'Final challenge!',
                          style: TextStyle(color: diamondColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDpadBtn(String iconName, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: AppIcons.svg(iconName, size: 26, color: Colors.white)),
      ),
    );
  }

  Widget _buildTile(int x, int y) {
    if (grid.isEmpty || y >= grid.length || x >= grid[y].length) {
      return const SizedBox();
    }

    bool isPlayer = x == playerX && y == playerY;
    if (isPlayer) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isDead ? Colors.red : const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Text(isDead ? '💀' : '🧑', style: const TextStyle(fontSize: 15))),
      );
    }

    int tile = grid[y][x];
    Color color;
    String? emoji;
    double fontSize = 15;

    switch (tile) {
      case wall: color = wallColor; emoji = null; break;
      case diamond: color = bgMedium; emoji = '💎'; break;
      case boulder: color = const Color(0xFF6B4423); emoji = '🪨'; break;
      case spike: color = bgMedium; emoji = '⚠️'; fontSize = 13; break;
      case exitTile: color = diamonds >= totalDiamonds ? Colors.green.withAlpha(150) : Colors.grey.withAlpha(100); emoji = '🚪'; break;
      case sand: color = sandColor; emoji = null; break;
      case fire: color = fireActive ? Colors.orange.withAlpha(150) : bgMedium; emoji = fireActive ? '🔥' : null; break;
      case breakableWall: color = const Color(0xFF8B7355); emoji = '🧱'; fontSize = 13; break;
      case keyTile: color = bgMedium; emoji = '🔑'; break;
      case lockedDoor: color = const Color(0xFF8B0000); emoji = '🔒'; break;
      default: color = bgMedium; emoji = null;
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: emoji != null ? Center(child: Text(emoji, style: TextStyle(fontSize: fontSize))) : null,
    );
  }
}
