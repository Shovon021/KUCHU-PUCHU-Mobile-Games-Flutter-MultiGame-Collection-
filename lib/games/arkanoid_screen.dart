import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

// Power-up types
enum PowerUpType {
  expand,    // Wider paddle
  shrink,    // Smaller paddle
  speedUp,   // Faster ball
  slowDown,  // Slower ball
  fireball,  // Ball goes through bricks
  extraLife, // +1 life
  multiBall, // Split into 3 balls
}

// Brick class
class Brick {
  double x, y, width, height;
  int hitsLeft;
  Color color;
  bool isDestroyed;
  PowerUpType? powerUp; // Some bricks contain power-ups

  Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.hitsLeft,
    required this.color,
    this.powerUp,
  }) : isDestroyed = false;

  int get points {
    if (hitsLeft == 3) return 50;
    if (hitsLeft == 2) return 25;
    return 10;
  }
}

// Ball class
class Ball {
  double x, y, dx, dy, radius;
  bool isFireball;

  Ball({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    this.radius = 8,
    this.isFireball = false,
  });
}

// Power-up falling object
class FallingPowerUp {
  double x, y;
  PowerUpType type;
  static const double size = 25;
  static const double fallSpeed = 3;

  FallingPowerUp({required this.x, required this.y, required this.type});

  Color get color {
    switch (type) {
      case PowerUpType.expand:
        return Colors.blue;
      case PowerUpType.shrink:
        return Colors.red;
      case PowerUpType.speedUp:
        return Colors.yellow;
      case PowerUpType.slowDown:
        return Colors.green;
      case PowerUpType.fireball:
        return Colors.orange;
      case PowerUpType.extraLife:
        return Colors.pink;
      case PowerUpType.multiBall:
        return Colors.purple;
    }
  }

  String get emoji {
    switch (type) {
      case PowerUpType.expand:
        return '⬌';
      case PowerUpType.shrink:
        return '⬄';
      case PowerUpType.speedUp:
        return '⚡';
      case PowerUpType.slowDown:
        return '🐢';
      case PowerUpType.fireball:
        return '🔥';
      case PowerUpType.extraLife:
        return '❤️';
      case PowerUpType.multiBall:
        return '🎯';
    }
  }
}

class ArkanoidScreen extends StatefulWidget {
  const ArkanoidScreen({super.key});

  @override
  State<ArkanoidScreen> createState() => _ArkanoidScreenState();
}

class _ArkanoidScreenState extends State<ArkanoidScreen> with SingleTickerProviderStateMixin {
  // Theme colors
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);
  static const Color paddleColor = Color(0xFF667EEA);
  static const Color ballColor = Color(0xFFFF6B6B);

  // Game dimensions (will be set based on screen size)
  double gameWidth = 0;
  double gameHeight = 0;

  // Paddle
  double paddleX = 0;
  double paddleWidth = 100;
  static const double paddleHeight = 15;
  static const double paddleY = 50; // Distance from bottom

  // Ball(s)
  List<Ball> balls = [];
  double baseBallSpeed = 5;
  double currentBallSpeed = 5;

  // Bricks
  List<Brick> bricks = [];
  static const int brickRows = 6;
  static const int brickCols = 8;
  static const double brickPadding = 4;

  // Power-ups
  List<FallingPowerUp> powerUps = [];
  Timer? fireballTimer;

  // Game state
  int score = 0;
  int lives = 3;
  int level = 1;
  bool isPlaying = false;
  bool isGameOver = false;
  bool isWin = false;
  bool showStartScreen = true;

  // Animation
  Ticker? _ticker;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    fireballTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    setState(() {
      // Center paddle
      paddleX = (gameWidth - paddleWidth) / 2;
      paddleWidth = 100; // Reset paddle width

      // Create initial ball
      balls = [_createBall()];
      currentBallSpeed = baseBallSpeed;

      // Create bricks for current level
      _createBricks();

      // Clear power-ups
      powerUps.clear();
      fireballTimer?.cancel();

      isPlaying = false;
      isGameOver = false;
      isWin = false;
    });
  }

  Ball _createBall() {
    return Ball(
      x: gameWidth / 2,
      y: gameHeight - paddleY - paddleHeight - 20,
      dx: ((_random.nextDouble() - 0.5) * 2) * currentBallSpeed,
      dy: -currentBallSpeed,
      isFireball: false,
    );
  }

  void _createBricks() {
    bricks.clear();
    final brickWidth = (gameWidth - (brickCols + 1) * brickPadding) / brickCols;
    const brickHeight = 20.0;
    final startY = 80.0;

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];

    for (int row = 0; row < brickRows; row++) {
      for (int col = 0; col < brickCols; col++) {
        final x = brickPadding + col * (brickWidth + brickPadding);
        final y = startY + row * (brickHeight + brickPadding);

        // Determine brick strength based on level and row
        int hits = 1;
        if (level >= 2 && row < 2) hits = 2;
        if (level >= 3 && row < 1) hits = 3;

        // Random power-up (15% chance)
        PowerUpType? powerUp;
        if (_random.nextDouble() < 0.15) {
          powerUp = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
        }

        bricks.add(Brick(
          x: x,
          y: y,
          width: brickWidth,
          height: brickHeight,
          hitsLeft: hits,
          color: colors[row % colors.length],
          powerUp: powerUp,
        ));
      }
    }
  }

  void _startGame() {
    if (showStartScreen) {
      setState(() => showStartScreen = false);
      _initGame();
      return;
    }

    if (!isPlaying && !isGameOver) {
      setState(() => isPlaying = true);
      _ticker?.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying) return;

    setState(() {
      // Update balls
      for (int i = balls.length - 1; i >= 0; i--) {
        _updateBall(balls[i], i);
      }

      // Update falling power-ups
      for (int i = powerUps.length - 1; i >= 0; i--) {
        powerUps[i].y += FallingPowerUp.fallSpeed;

        // Check if caught by paddle
        if (_isPowerUpCaught(powerUps[i])) {
          _applyPowerUp(powerUps[i].type);
          SoundService.playSuccess();
          powerUps.removeAt(i);
        } else if (powerUps[i].y > gameHeight) {
          powerUps.removeAt(i);
        }
      }

      // Check win condition
      if (bricks.every((b) => b.isDestroyed || b.hitsLeft < 0)) {
        _nextLevel();
      }
    });
  }

  void _updateBall(Ball ball, int index) {
    ball.x += ball.dx;
    ball.y += ball.dy;

    // Wall collisions
    if (ball.x <= ball.radius) {
      ball.x = ball.radius;
      ball.dx = ball.dx.abs();
    }
    if (ball.x >= gameWidth - ball.radius) {
      ball.x = gameWidth - ball.radius;
      ball.dx = -ball.dx.abs();
    }
    if (ball.y <= ball.radius) {
      ball.y = ball.radius;
      ball.dy = ball.dy.abs();
    }

    // Bottom - lose ball
    if (ball.y >= gameHeight - ball.radius) {
      balls.removeAt(index);
      if (balls.isEmpty) {
        _loseLife();
      }
      return;
    }

    // Paddle collision
    if (_isPaddleCollision(ball)) {
      ball.dy = -ball.dy.abs();
      // Adjust angle based on where ball hit paddle
      final hitPos = (ball.x - paddleX) / paddleWidth;
      ball.dx = (hitPos - 0.5) * 2 * currentBallSpeed;
      SoundService.playTap();
    }

    // Brick collisions
    for (var brick in bricks) {
      if (!brick.isDestroyed && _isBrickCollision(ball, brick)) {
        if (!ball.isFireball) {
          // Determine which side was hit
          final ballCenterX = ball.x;
          final ballCenterY = ball.y;
          final brickCenterX = brick.x + brick.width / 2;
          final brickCenterY = brick.y + brick.height / 2;

          final dx = ballCenterX - brickCenterX;
          final dy = ballCenterY - brickCenterY;

          if (dx.abs() / brick.width > dy.abs() / brick.height) {
            ball.dx = -ball.dx;
          } else {
            ball.dy = -ball.dy;
          }
        }

        _hitBrick(brick);
        SoundService.playTap();
        break; // Only hit one brick per frame
      }
    }
  }

  bool _isPaddleCollision(Ball ball) {
    final paddleTop = gameHeight - paddleY - paddleHeight;
    return ball.y + ball.radius >= paddleTop &&
        ball.y - ball.radius <= paddleTop + paddleHeight &&
        ball.x >= paddleX &&
        ball.x <= paddleX + paddleWidth &&
        ball.dy > 0;
  }

  bool _isBrickCollision(Ball ball, Brick brick) {
    return ball.x + ball.radius >= brick.x &&
        ball.x - ball.radius <= brick.x + brick.width &&
        ball.y + ball.radius >= brick.y &&
        ball.y - ball.radius <= brick.y + brick.height;
  }

  bool _isPowerUpCaught(FallingPowerUp powerUp) {
    final paddleTop = gameHeight - paddleY - paddleHeight;
    return powerUp.y + FallingPowerUp.size >= paddleTop &&
        powerUp.y <= paddleTop + paddleHeight &&
        powerUp.x + FallingPowerUp.size >= paddleX &&
        powerUp.x <= paddleX + paddleWidth;
  }

  void _hitBrick(Brick brick) {
    brick.hitsLeft--;
    if (brick.hitsLeft <= 0) {
      brick.isDestroyed = true;
      score += brick.points;

      // Spawn power-up if brick had one
      if (brick.powerUp != null) {
        powerUps.add(FallingPowerUp(
          x: brick.x + brick.width / 2 - FallingPowerUp.size / 2,
          y: brick.y,
          type: brick.powerUp!,
        ));
      }
    } else {
      // Change color to show damage
      brick.color = brick.color.withAlpha(200);
    }
  }

  void _applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.expand:
        paddleWidth = min(paddleWidth + 30, 180);
        break;
      case PowerUpType.shrink:
        paddleWidth = max(paddleWidth - 20, 50);
        break;
      case PowerUpType.speedUp:
        currentBallSpeed = min(currentBallSpeed + 1, 10);
        for (var ball in balls) {
          final factor = currentBallSpeed / (currentBallSpeed - 1);
          ball.dx *= factor;
          ball.dy *= factor;
        }
        break;
      case PowerUpType.slowDown:
        currentBallSpeed = max(currentBallSpeed - 1, 3);
        for (var ball in balls) {
          final factor = currentBallSpeed / (currentBallSpeed + 1);
          ball.dx *= factor;
          ball.dy *= factor;
        }
        break;
      case PowerUpType.fireball:
        for (var ball in balls) {
          ball.isFireball = true;
        }
        fireballTimer?.cancel();
        fireballTimer = Timer(const Duration(seconds: 5), () {
          for (var ball in balls) {
            ball.isFireball = false;
          }
        });
        break;
      case PowerUpType.extraLife:
        lives++;
        break;
      case PowerUpType.multiBall:
        if (balls.isNotEmpty) {
          final original = balls.first;
          balls.add(Ball(
            x: original.x,
            y: original.y,
            dx: currentBallSpeed,
            dy: -currentBallSpeed,
            isFireball: original.isFireball,
          ));
          balls.add(Ball(
            x: original.x,
            y: original.y,
            dx: -currentBallSpeed,
            dy: -currentBallSpeed,
            isFireball: original.isFireball,
          ));
        }
        break;
    }
  }

  void _loseLife() {
    lives--;
    if (lives <= 0) {
      _ticker?.stop();
      isPlaying = false;
      isGameOver = true;
      SoundService.playFail();
    } else {
      // Reset ball
      balls = [_createBall()];
      isPlaying = false;
      _ticker?.stop();
      SoundService.playFail();
    }
  }

  void _nextLevel() {
    _ticker?.stop();
    isPlaying = false;
    level++;
    baseBallSpeed += 0.5;
    currentBallSpeed = baseBallSpeed;
    score += 100 * level; // Level bonus
    SoundService.playSuccess();
    _initGame();
  }

  void _movePaddle(double deltaX) {
    setState(() {
      paddleX += deltaX;
      paddleX = paddleX.clamp(0, gameWidth - paddleWidth);

      // If not playing, ball follows paddle
      if (!isPlaying && balls.isNotEmpty) {
        balls.first.x = paddleX + paddleWidth / 2;
      }
    });
  }

  void _resetGame() {
    setState(() {
      score = 0;
      lives = 3;
      level = 1;
      baseBallSpeed = 5;
      currentBallSpeed = 5;
      isGameOver = false;
      isWin = false;
    });
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Set game dimensions on first build
          if (gameWidth == 0) {
            gameWidth = constraints.maxWidth;
            gameHeight = constraints.maxHeight;
            WidgetsBinding.instance.addPostFrameCallback((_) => _initGame());
          }

          if (showStartScreen) {
            return _buildStartScreen();
          }

          return GestureDetector(
            onHorizontalDragUpdate: (details) => _movePaddle(details.delta.dx),
            onTap: _startGame,
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent || event is KeyRepeatEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _movePaddle(-15);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _movePaddle(15);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.space) {
                    _startGame();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Game elements
                  CustomPaint(
                    size: Size(gameWidth, gameHeight),
                    painter: _ArkanoidPainter(
                      bricks: bricks,
                      balls: balls,
                      powerUps: powerUps,
                      paddleX: paddleX,
                      paddleWidth: paddleWidth,
                      paddleY: gameHeight - paddleY - paddleHeight,
                      paddleColor: paddleColor,
                      ballColor: ballColor,
                    ),
                  ),

                  // Top HUD
                  _buildHUD(),

                  // Pause/Start overlay
                  if (!isPlaying && !isGameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'Tap to Launch',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Game Over overlay
                  if (isGameOver) _buildGameOverOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Back button
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
            // Title
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppIcons.svg('brick', size: 60, color: Colors.white),
            ),
            const SizedBox(height: 25),
            const Text(
              'ARKANOID',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Break the bricks!',
              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16),
            ),
            const SizedBox(height: 50),
            // Start button
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcons.svg('play', size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Start Game', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.arkanoid),
              icon: AppIcons.help(color: Colors.white70),
              label: const Text('How to Play?', style: TextStyle(color: Colors.white70)),
            ),
            const Spacer(),
            // Controls hint
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '← Drag to move paddle →',
                style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              icon: AppIcons.back(color: Colors.white),
              onPressed: () {
                _ticker?.stop();
                Navigator.pop(context);
              },
            ),
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AppIcons.trophy(size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '$score',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lv.$level',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // Lives
            Row(
              children: List.generate(
                lives,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: AppIcons.svg('heart', size: 20, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.svg('sad-face', size: 60, color: Colors.grey),
              const SizedBox(height: 15),
              const Text(
                'Game Over',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 10),
              Text(
                'Score: $score',
                style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              ),
              Text(
                'Level: $level',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _resetGame,
                    icon: AppIcons.refresh(size: 20, color: Colors.white),
                    label: const Text('Play Again', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(width: 15),
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
    );
  }
}

// Custom painter for game elements
class _ArkanoidPainter extends CustomPainter {
  final List<Brick> bricks;
  final List<Ball> balls;
  final List<FallingPowerUp> powerUps;
  final double paddleX, paddleWidth, paddleY;
  final Color paddleColor, ballColor;

  _ArkanoidPainter({
    required this.bricks,
    required this.balls,
    required this.powerUps,
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleY,
    required this.paddleColor,
    required this.ballColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw bricks
    for (var brick in bricks) {
      if (!brick.isDestroyed) {
        paint.color = brick.color;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(brick.x, brick.y, brick.width, brick.height),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);

        // Draw hit indicator for multi-hit bricks
        if (brick.hitsLeft > 1) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${brick.hitsLeft}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              brick.x + brick.width / 2 - textPainter.width / 2,
              brick.y + brick.height / 2 - textPainter.height / 2,
            ),
          );
        }

        // Draw power-up indicator
        if (brick.powerUp != null) {
          paint.color = Colors.white.withAlpha(80);
          canvas.drawCircle(
            Offset(brick.x + brick.width / 2, brick.y + brick.height / 2),
            5,
            paint,
          );
        }
      }
    }

    // Draw paddle
    paint.color = paddleColor;
    final paddleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(paddleX, paddleY, paddleWidth, 15),
      const Radius.circular(8),
    );
    canvas.drawRRect(paddleRect, paint);

    // Draw paddle gradient effect
    paint.shader = LinearGradient(
      colors: [Colors.white.withAlpha(50), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(paddleX, paddleY, paddleWidth, 15));
    canvas.drawRRect(paddleRect, paint);
    paint.shader = null;

    // Draw balls
    for (var ball in balls) {
      if (ball.isFireball) {
        // Fireball glow effect
        paint.color = Colors.orange.withAlpha(100);
        canvas.drawCircle(Offset(ball.x, ball.y), ball.radius + 5, paint);
        paint.color = Colors.orange;
      } else {
        paint.color = ballColor;
      }
      canvas.drawCircle(Offset(ball.x, ball.y), ball.radius, paint);

      // Ball highlight
      paint.color = Colors.white.withAlpha(100);
      canvas.drawCircle(Offset(ball.x - 2, ball.y - 2), ball.radius / 3, paint);
    }

    // Draw power-ups
    for (var powerUp in powerUps) {
      paint.color = powerUp.color;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(powerUp.x, powerUp.y, FallingPowerUp.size, FallingPowerUp.size),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Draw emoji
      final textPainter = TextPainter(
        text: TextSpan(text: powerUp.emoji, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          powerUp.x + FallingPowerUp.size / 2 - textPainter.width / 2,
          powerUp.y + FallingPowerUp.size / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArkanoidPainter oldDelegate) => true;
}
