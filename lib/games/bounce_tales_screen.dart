import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class BounceTalesScreen extends StatefulWidget {
  const BounceTalesScreen({super.key});

  @override
  State<BounceTalesScreen> createState() => _BounceTalesScreenState();
}

class _BounceTalesScreenState extends State<BounceTalesScreen> with TickerProviderStateMixin {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color ballColor = Color(0xFFE53935);
  static const Color platformColor = Color(0xFF4CAF50);
  static const Color coinColor = Color(0xFFFFC107);
  static const Color skyColor = Color(0xFF87CEEB);
  static const Color groundColor = Color(0xFF8B4513);

  // Physics constants
  static const double gravity = 0.5;
  static const double friction = 0.98;
  static const double slopeFriction = 0.95;
  static const double bounceFactor = 0.3;
  static const double moveSpeed = 0.4;
  static const double jumpForce = -12.0;
  static const double maxVelocity = 15.0;

  // Ball properties
  double ballX = 50;
  double ballY = 200;
  double ballVelX = 0;
  double ballVelY = 0;
  double ballRadius = 15;
  bool isOnGround = false;
  bool isDead = false;
  bool levelComplete = false;

  // Game state
  int currentLevel = 1;
  int totalLevels = 5;
  int coins = 0;
  int totalCoins = 0;
  int lives = 3;
  bool gameStarted = false;
  bool isPaused = false;

  // Controls
  bool movingLeft = false;
  bool movingRight = false;

  // Camera
  double cameraX = 0;
  double cameraY = 0;

  // Level data
  List<Platform> platforms = [];
  List<Spike> spikes = [];
  List<Coin> levelCoins = [];
  double finishX = 0;
  double levelWidth = 0;
  double levelHeight = 600;

  late AnimationController _gameLoopController;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      currentLevel = 1;
      lives = 3;
      coins = 0;
    });
    _loadLevel(currentLevel);
    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!isPaused && !isDead && !levelComplete) {
        _updatePhysics();
      }
    });
  }

  void _loadLevel(int level) {
    platforms.clear();
    spikes.clear();
    levelCoins.clear();

    switch (level) {
      case 1:
        _loadLevel1();
        break;
      case 2:
        _loadLevel2();
        break;
      case 3:
        _loadLevel3();
        break;
      case 4:
        _loadLevel4();
        break;
      case 5:
        _loadLevel5();
        break;
    }

    setState(() {
      ballX = 50;
      ballY = 200;
      ballVelX = 0;
      ballVelY = 0;
      isDead = false;
      levelComplete = false;
      cameraX = 0;
      totalCoins = levelCoins.length;
    });
  }

  // Level 1: Tutorial - Easy platforms
  void _loadLevel1() {
    levelWidth = 1500;
    finishX = 1400;
    
    // Ground
    platforms.add(Platform(0, 500, 400, 100, 0));
    platforms.add(Platform(500, 500, 300, 100, 0));
    platforms.add(Platform(900, 500, 500, 100, 0));
    
    // Floating platforms
    platforms.add(Platform(350, 400, 100, 20, 0));
    platforms.add(Platform(750, 350, 100, 20, 0));
    
    // Coins
    levelCoins.add(Coin(370, 370));
    levelCoins.add(Coin(770, 320));
    levelCoins.add(Coin(1100, 470));
  }

  // Level 2: Slopes introduced
  void _loadLevel2() {
    levelWidth = 2000;
    finishX = 1900;
    
    // Ground with slope
    platforms.add(Platform(0, 500, 300, 100, 0));
    platforms.add(Platform(300, 450, 200, 50, -15)); // Upward slope
    platforms.add(Platform(500, 400, 200, 100, 0));
    platforms.add(Platform(700, 400, 200, 50, 15)); // Downward slope
    platforms.add(Platform(900, 450, 300, 100, 0));
    platforms.add(Platform(1300, 500, 200, 100, 0));
    platforms.add(Platform(1600, 500, 400, 100, 0));
    
    // Floating platforms
    platforms.add(Platform(1150, 380, 100, 20, 0));
    
    // Coins
    levelCoins.add(Coin(350, 400));
    levelCoins.add(Coin(600, 370));
    levelCoins.add(Coin(1170, 350));
    levelCoins.add(Coin(1700, 470));
    
    // One small spike
    spikes.add(Spike(1250, 480, 30, 20));
  }

  // Level 3: More gaps and spikes
  void _loadLevel3() {
    levelWidth = 2500;
    finishX = 2400;
    
    platforms.add(Platform(0, 500, 200, 100, 0));
    platforms.add(Platform(280, 500, 150, 100, 0));
    platforms.add(Platform(500, 450, 100, 20, 0));
    platforms.add(Platform(680, 400, 100, 20, 0));
    platforms.add(Platform(860, 350, 100, 20, 0));
    platforms.add(Platform(1000, 400, 200, 100, 0));
    platforms.add(Platform(1000, 350, 200, 50, -10)); // Ramp up
    platforms.add(Platform(1300, 500, 300, 100, 0));
    platforms.add(Platform(1700, 500, 150, 100, 0));
    platforms.add(Platform(1950, 450, 150, 100, 0));
    platforms.add(Platform(2150, 500, 350, 100, 0));
    
    // Spikes
    spikes.add(Spike(230, 480, 30, 20));
    spikes.add(Spike(1400, 480, 30, 20));
    spikes.add(Spike(1450, 480, 30, 20));
    spikes.add(Spike(1880, 480, 40, 20));
    
    // Coins
    levelCoins.add(Coin(520, 420));
    levelCoins.add(Coin(700, 370));
    levelCoins.add(Coin(880, 320));
    levelCoins.add(Coin(1100, 300));
    levelCoins.add(Coin(2250, 470));
  }

  // Level 4: Complex slopes and timing
  void _loadLevel4() {
    levelWidth = 3000;
    finishX = 2900;
    
    platforms.add(Platform(0, 500, 150, 100, 0));
    platforms.add(Platform(150, 450, 150, 50, -20)); // Steep up
    platforms.add(Platform(300, 350, 200, 100, 0));
    platforms.add(Platform(500, 350, 150, 50, 20)); // Steep down
    platforms.add(Platform(650, 450, 200, 100, 0));
    platforms.add(Platform(950, 400, 100, 20, 0));
    platforms.add(Platform(1100, 350, 100, 20, 0));
    platforms.add(Platform(1250, 300, 100, 20, 0));
    platforms.add(Platform(1400, 350, 200, 100, 0));
    platforms.add(Platform(1700, 450, 150, 100, 0));
    platforms.add(Platform(1950, 500, 200, 100, 0));
    platforms.add(Platform(2250, 450, 150, 50, -15));
    platforms.add(Platform(2400, 380, 200, 100, 0));
    platforms.add(Platform(2700, 500, 300, 100, 0));
    
    // Spikes
    spikes.add(Spike(880, 480, 40, 20));
    spikes.add(Spike(1650, 330, 30, 20));
    spikes.add(Spike(2180, 480, 40, 20));
    spikes.add(Spike(2650, 480, 30, 20));
    
    // Coins
    levelCoins.add(Coin(250, 400));
    levelCoins.add(Coin(400, 320));
    levelCoins.add(Coin(970, 370));
    levelCoins.add(Coin(1270, 270));
    levelCoins.add(Coin(1970, 470));
    levelCoins.add(Coin(2800, 470));
  }

  // Level 5: Final challenge
  void _loadLevel5() {
    levelWidth = 3500;
    finishX = 3400;
    
    platforms.add(Platform(0, 500, 100, 100, 0));
    platforms.add(Platform(180, 450, 80, 20, 0));
    platforms.add(Platform(340, 400, 80, 20, 0));
    platforms.add(Platform(500, 350, 80, 20, 0));
    platforms.add(Platform(660, 300, 150, 100, 0));
    platforms.add(Platform(660, 250, 150, 50, -25)); // Very steep
    platforms.add(Platform(900, 400, 100, 20, 0));
    platforms.add(Platform(1080, 450, 100, 20, 0));
    platforms.add(Platform(1260, 400, 100, 20, 0));
    platforms.add(Platform(1440, 350, 200, 100, 0));
    platforms.add(Platform(1750, 400, 100, 20, 0));
    platforms.add(Platform(1930, 350, 100, 20, 0));
    platforms.add(Platform(2100, 400, 150, 100, 0));
    platforms.add(Platform(2350, 450, 100, 20, 0));
    platforms.add(Platform(2530, 400, 100, 20, 0));
    platforms.add(Platform(2700, 350, 200, 100, 0));
    platforms.add(Platform(3000, 450, 150, 100, 0));
    platforms.add(Platform(3200, 500, 300, 100, 0));
    
    // Many spikes
    spikes.add(Spike(130, 480, 30, 20));
    spikes.add(Spike(850, 380, 30, 20));
    spikes.add(Spike(1700, 380, 30, 20));
    spikes.add(Spike(2050, 380, 30, 20));
    spikes.add(Spike(2300, 430, 30, 20));
    spikes.add(Spike(2950, 430, 30, 20));
    spikes.add(Spike(3160, 480, 30, 20));
    
    // Coins
    levelCoins.add(Coin(200, 420));
    levelCoins.add(Coin(360, 370));
    levelCoins.add(Coin(520, 320));
    levelCoins.add(Coin(720, 200));
    levelCoins.add(Coin(1500, 320));
    levelCoins.add(Coin(2150, 370));
    levelCoins.add(Coin(2750, 320));
    levelCoins.add(Coin(3300, 470));
  }

  void _updatePhysics() {
    // Apply gravity
    ballVelY += gravity;

    // Apply horizontal movement
    if (movingLeft) ballVelX -= moveSpeed;
    if (movingRight) ballVelX += moveSpeed;

    // Apply friction
    ballVelX *= friction;

    // Clamp velocity
    ballVelX = ballVelX.clamp(-maxVelocity, maxVelocity);
    ballVelY = ballVelY.clamp(-maxVelocity, maxVelocity * 1.5);

    // Store old Y position for collision
    double oldY = ballY;

    // Update position
    ballX += ballVelX;
    ballY += ballVelY;

    isOnGround = false;

    // Check platform collisions
    for (var platform in platforms) {
      if (_checkPlatformCollision(platform, oldY)) break;
    }

    // Check spike collisions
    for (var spike in spikes) {
      if (_checkSpikeCollision(spike)) {
        _onDeath();
        return;
      }
    }

    // Check coin collisions
    levelCoins.removeWhere((coin) {
      if (_checkCoinCollision(coin)) {
        coins++;
        return true;
      }
      return false;
    });

    // Check fall death
    if (ballY > levelHeight + 100) {
      _onDeath();
      return;
    }

    // Check level complete
    if (ballX > finishX) {
      _onLevelComplete();
      return;
    }

    // Update camera
    cameraX = (ballX - 200).clamp(0, levelWidth - 400);

    setState(() {});
  }

  bool _checkPlatformCollision(Platform platform, double oldY) {
    // Get platform bounds considering rotation
    double platLeft = platform.x;
    double platRight = platform.x + platform.width;
    double platTop = platform.y;
    double platBottom = platform.y + platform.height;

    // Adjust for slope
    if (platform.angle != 0) {
      double relativeX = ballX - platform.x;
      double slopeOffset = tan(platform.angle * pi / 180) * relativeX;
      platTop += slopeOffset;
    }

    // Check if ball is within platform bounds
    if (ballX + ballRadius > platLeft && 
        ballX - ballRadius < platRight &&
        ballY + ballRadius > platTop &&
        ballY - ballRadius < platBottom) {
      
      // Coming from above
      if (oldY + ballRadius <= platTop + 5) {
        ballY = platTop - ballRadius;
        if (ballVelY > 0) {
          ballVelY = -ballVelY * bounceFactor;
          if (ballVelY.abs() < 2) ballVelY = 0;
        }
        isOnGround = true;

        // Apply slope physics
        if (platform.angle != 0) {
          double slopeForce = sin(platform.angle * pi / 180) * gravity * 2;
          ballVelX += slopeForce;
          ballVelX *= slopeFriction;
        }
        return true;
      }
      // Side collision
      else {
        if (ballX < platform.x + platform.width / 2) {
          ballX = platLeft - ballRadius;
        } else {
          ballX = platRight + ballRadius;
        }
        ballVelX = -ballVelX * 0.5;
      }
    }
    return false;
  }

  bool _checkSpikeCollision(Spike spike) {
    double dx = ballX - (spike.x + spike.width / 2);
    double dy = ballY - spike.y;
    return dx.abs() < spike.width / 2 + ballRadius * 0.5 && 
           dy.abs() < spike.height + ballRadius * 0.5 &&
           ballY > spike.y - spike.height;
  }

  bool _checkCoinCollision(Coin coin) {
    double dx = ballX - coin.x;
    double dy = ballY - coin.y;
    if (sqrt(dx * dx + dy * dy) < ballRadius + 12) {
      SoundService.playCoin();
      return true;
    }
    return false;
  }

  void _jump() {
    if (isOnGround && !isDead && !levelComplete) {
      SoundService.playJump();
      ballVelY = jumpForce;
      isOnGround = false;
      HapticFeedback.lightImpact();
    }
  }

  void _onDeath() {
    setState(() {
      isDead = true;
      lives--;
    });
    SoundService.playGameOver();
    HapticFeedback.heavyImpact();
    
    if (lives <= 0) {
      _showGameOverDialog();
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _loadLevel(currentLevel);
      });
    }
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

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(children: [
          AppIcons.svg('sad-face', size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Game Over', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Level $currentLevel • Coins: $coins', style: const TextStyle(color: Colors.grey)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ballColor),
            onPressed: () { Navigator.pop(context); _startGame(); },
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(children: [
          AppIcons.trophy(size: 60, color: Colors.amber),
          const SizedBox(height: 10),
          const Text('Victory!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
          Text('All $totalLevels levels completed!', style: const TextStyle(color: Colors.grey)),
          Text('Total Coins: $coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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
      backgroundColor: skyColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bounce ball logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: ballColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: ballColor.withAlpha(100), blurRadius: 30)],
                ),
                child: const Center(child: Text('🔴', style: TextStyle(fontSize: 50))),
              ),
              const SizedBox(height: 30),
              const Text('Bounce Tales', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 5)])),
              const Text('Classic Platformer', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: platformColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AppIcons.svg('play', size: 30, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(15)),
                child: const Column(children: [
                  Text('Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  Text('◀ ▶ to roll • TAP to jump'),
                  Text('Collect coins • Avoid spikes!'),
                ]),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => showHowToPlay(context, GameRules.bounceTales),
                icon: AppIcons.help(color: Colors.white70),
                label: const Text('How to Play?', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas
          GestureDetector(
            onTap: _jump,
            child: Container(
              color: skyColor,
              child: CustomPaint(
                painter: GamePainter(
                  ballX: ballX,
                  ballY: ballY,
                  ballRadius: ballRadius,
                  cameraX: cameraX,
                  platforms: platforms,
                  spikes: spikes,
                  coins: levelCoins,
                  finishX: finishX,
                  levelWidth: levelWidth,
                  isDead: isDead,
                  levelComplete: levelComplete,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: AppIcons.back(color: Colors.white),
                    onPressed: () {
                      _gameTimer?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                  // Level
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                    child: Text('Level $currentLevel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  // Coins & Lives
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: coinColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('🪙 $coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: ballColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('❤️ $lives', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // Status message
          if (isDead || levelComplete)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: isDead ? ballColor : platformColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDead ? (lives > 0 ? 'Oops! Try again...' : 'Game Over!') : 'Level Complete!',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Control buttons - Left hand: L/R | Right hand: Jump
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT HAND - Movement controls (Left + Right side by side)
                  Row(
                    children: [
                      // Left button
                      GestureDetector(
                        onTapDown: (_) => setState(() => movingLeft = true),
                        onTapUp: (_) => setState(() => movingLeft = false),
                        onTapCancel: () => setState(() => movingLeft = false),
                        onPanEnd: (_) => setState(() => movingLeft = false),
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: movingLeft ? Colors.white : Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 5)],
                          ),
                          child: AppIcons.svg('arrow-left', size: 35, color: movingLeft ? platformColor : Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Right button
                      GestureDetector(
                        onTapDown: (_) => setState(() => movingRight = true),
                        onTapUp: (_) => setState(() => movingRight = false),
                        onTapCancel: () => setState(() => movingRight = false),
                        onPanEnd: (_) => setState(() => movingRight = false),
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: movingRight ? Colors.white : Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 5)],
                          ),
                          child: AppIcons.svg('arrow-right', size: 35, color: movingRight ? platformColor : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  // RIGHT HAND - Jump button (large)
                  GestureDetector(
                    onTapDown: (_) => _jump(),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ballColor, ballColor.withAlpha(200)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: ballColor.withAlpha(100), blurRadius: 15, spreadRadius: 2)],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcons.svg('arrow-up', size: 40, color: Colors.white),
                          const Text('JUMP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes
class Platform {
  final double x, y, width, height, angle;
  Platform(this.x, this.y, this.width, this.height, this.angle);
}

class Spike {
  final double x, y, width, height;
  Spike(this.x, this.y, this.width, this.height);
}

class Coin {
  final double x, y;
  Coin(this.x, this.y);
}

// Custom painter for the game
class GamePainter extends CustomPainter {
  final double ballX, ballY, ballRadius, cameraX, finishX, levelWidth;
  final List<Platform> platforms;
  final List<Spike> spikes;
  final List<Coin> coins;
  final bool isDead, levelComplete;

  GamePainter({
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.cameraX,
    required this.platforms,
    required this.spikes,
    required this.coins,
    required this.finishX,
    required this.levelWidth,
    required this.isDead,
    required this.levelComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw platforms
    final platformPaint = Paint()..color = const Color(0xFF4CAF50);
    final groundPaint = Paint()..color = const Color(0xFF8B4513);
    
    for (var platform in platforms) {
      canvas.save();
      if (platform.angle != 0) {
        canvas.translate(platform.x - cameraX + platform.width / 2, platform.y);
        canvas.rotate(platform.angle * pi / 180);
        canvas.translate(-(platform.x - cameraX + platform.width / 2), -platform.y);
      }
      
      // Draw grass on top
      final rect = Rect.fromLTWH(platform.x - cameraX, platform.y, platform.width, platform.height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), platformPaint);
      
      // Draw dirt below
      if (platform.height > 30) {
        final dirtRect = Rect.fromLTWH(platform.x - cameraX, platform.y + 15, platform.width, platform.height - 15);
        canvas.drawRect(dirtRect, groundPaint);
      }
      
      canvas.restore();
    }

    // Draw spikes
    final spikePaint = Paint()..color = const Color(0xFF424242);
    for (var spike in spikes) {
      final path = Path();
      path.moveTo(spike.x - cameraX, spike.y);
      path.lineTo(spike.x + spike.width / 2 - cameraX, spike.y - spike.height);
      path.lineTo(spike.x + spike.width - cameraX, spike.y);
      path.close();
      canvas.drawPath(path, spikePaint);
    }

    // Draw coins
    final coinPaint = Paint()..color = const Color(0xFFFFC107);
    final coinBorder = Paint()..color = const Color(0xFFFF8F00)..style = PaintingStyle.stroke..strokeWidth = 2;
    for (var coin in coins) {
      canvas.drawCircle(Offset(coin.x - cameraX, coin.y), 12, coinPaint);
      canvas.drawCircle(Offset(coin.x - cameraX, coin.y), 12, coinBorder);
      // $ symbol
      final textPainter = TextPainter(
        text: const TextSpan(text: '\$', style: TextStyle(color: Color(0xFFFF8F00), fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(coin.x - cameraX - 4, coin.y - 8));
    }

    // Draw finish flag
    final flagPaint = Paint()..color = Colors.white;
    final polePaint = Paint()..color = Colors.brown..strokeWidth = 4;
    canvas.drawLine(Offset(finishX - cameraX, 300), Offset(finishX - cameraX, 500), polePaint);
    final flagPath = Path()
      ..moveTo(finishX - cameraX, 300)
      ..lineTo(finishX + 40 - cameraX, 320)
      ..lineTo(finishX - cameraX, 340)
      ..close();
    canvas.drawPath(flagPath, flagPaint);
    canvas.drawPath(flagPath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);

    // Draw ball
    final ballPaint = Paint()..color = isDead ? Colors.grey : const Color(0xFFE53935);
    final ballHighlight = Paint()..color = Colors.white.withAlpha(100);
    canvas.drawCircle(Offset(ballX - cameraX, ballY), ballRadius, ballPaint);
    canvas.drawCircle(Offset(ballX - cameraX - 4, ballY - 4), ballRadius * 0.3, ballHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
