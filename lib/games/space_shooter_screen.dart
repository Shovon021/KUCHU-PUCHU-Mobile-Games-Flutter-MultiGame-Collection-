import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../widgets/app_icons.dart';
import '../services/sound_service.dart';
import '../services/high_score_service.dart';
import '../widgets/how_to_play.dart';

class SpaceShooterScreen extends StatefulWidget {
  const SpaceShooterScreen({super.key});

  @override
  State<SpaceShooterScreen> createState() => _SpaceShooterScreenState();
}

class _SpaceShooterScreenState extends State<SpaceShooterScreen> with TickerProviderStateMixin {
  // Game Loop
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final Random _random = Random();

  // Game State
  bool isPlaying = false;
  bool isGameOver = false;
  bool isVictory = false;
  int score = 0;
  int lives = 3;
  int wave = 1;
  int level = 1;
  bool isBossPhase = false;
  Boss? currentBoss;
  int killsThisLevel = 0;
  int killsToSpawnBoss = 15; // Kill 15 enemies to spawn boss
  int highScore = 0;
  bool isNewHighScore = false;

  // Player
  double playerX = 0;
  double playerWidth = 40;
  double fireCooldown = 0;
  double fireRate = 0.15; // Seconds between shots
  bool hasDoubleShot = false;
  bool hasShield = false;
  double shieldTime = 0;

  // Entities
  List<Bullet> playerBullets = [];
  List<Bullet> enemyBullets = [];
  List<Alien> aliens = [];
  List<Star> stars = [];
  List<Particle> particles = [];
  List<PowerUp> powerUps = [];

  // Spawn Timers
  double alienSpawnTimer = 0;
  double alienSpawnRate = 2.0; // Seconds

  // Screen
  Size screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _initStars();
    highScore = HighScoreService.getHighScore(HighScoreService.spaceShooter);
  }

  void _initStars() {
    stars.clear();
    for (int i = 0; i < 50; i++) {
      stars.add(Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble() * 1.5,
        size: 1 + _random.nextDouble() * 2,
      ));
    }
  }

  void _initGame() {
    playerX = 0.5;
    score = 0;
    lives = 3;
    wave = 1;
    level = 1;
    isBossPhase = false;
    currentBoss = null;
    killsThisLevel = 0;
    killsToSpawnBoss = 15;
    isVictory = false;
    hasDoubleShot = false;
    hasShield = false;
    shieldTime = 0;
    playerBullets.clear();
    enemyBullets.clear();
    aliens.clear();
    particles.clear();
    powerUps.clear();
    alienSpawnRate = 2.0;
    _initStars();
  }

  void _startGame() {
    _initGame();
    setState(() {
      isPlaying = true;
      isGameOver = false;
    });
    if (_ticker.isTicking) _ticker.stop();
    _lastTick = Duration.zero;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying || isGameOver || screenSize == Size.zero) return;

    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;

    // Update Stars (Parallax)
    for (var star in stars) {
      star.y += star.speed * dt * 0.1;
      if (star.y > 1) {
        star.y = 0;
        star.x = _random.nextDouble();
      }
    }

    // Auto-Fire
    fireCooldown -= dt;
    if (fireCooldown <= 0) {
      _firePlayerBullet();
      fireCooldown = fireRate;
    }

    // Update Bullets
    _updateBullets(dt);

    // Check if it's time to spawn boss
    if (!isBossPhase && killsThisLevel >= killsToSpawnBoss) {
      _spawnBoss();
    }

    // Spawn Aliens (only if not in boss phase)
    if (!isBossPhase) {
      alienSpawnTimer -= dt;
      if (alienSpawnTimer <= 0) {
        _spawnAlien();
        alienSpawnTimer = alienSpawnRate;
      }
    }

    // Update Aliens
    _updateAliens(dt);

    // Update Boss
    _updateBoss(dt);

    // Update Particles
    _updateParticles(dt);

    // Update PowerUps
    _updatePowerUps(dt);

    // Shield Timer
    if (hasShield) {
      shieldTime -= dt;
      if (shieldTime <= 0) hasShield = false;
    }

    // Check Collisions
    _checkCollisions();

    setState(() {});
  }

  void _firePlayerBullet() {
    double bulletX = playerX;
    playerBullets.add(Bullet(x: bulletX, y: 0.85, isPlayerBullet: true));
    if (hasDoubleShot) {
      playerBullets.add(Bullet(x: bulletX - 0.03, y: 0.87, isPlayerBullet: true));
      playerBullets.add(Bullet(x: bulletX + 0.03, y: 0.87, isPlayerBullet: true));
    }
    SoundService.playTap();
  }

  void _updateBullets(double dt) {
    // Player bullets move up
    for (int i = playerBullets.length - 1; i >= 0; i--) {
      playerBullets[i].y -= dt * 1.5;
      if (playerBullets[i].y < -0.05) {
        playerBullets.removeAt(i);
      }
    }
    // Enemy bullets move down
    for (int i = enemyBullets.length - 1; i >= 0; i--) {
      enemyBullets[i].y += dt * 0.8;
      if (enemyBullets[i].y > 1.05) {
        enemyBullets.removeAt(i);
      }
    }
  }

  void _spawnAlien() {
    // Don't spawn aliens during boss phase
    if (isBossPhase) return;

    AlienType type = AlienType.basic;
    // Higher levels = harder enemies
    if (level >= 2 && _random.nextDouble() < 0.3) type = AlienType.fast;
    if (level >= 4 && _random.nextDouble() < 0.25) type = AlienType.tank;

    double x = 0.1 + _random.nextDouble() * 0.8;
    MovementPattern pattern = MovementPattern.values[_random.nextInt(MovementPattern.values.length)];

    aliens.add(Alien(
      x: x,
      y: -0.1,
      type: type,
      pattern: pattern,
      phaseOffset: _random.nextDouble() * pi * 2,
    ));
  }

  void _spawnBoss() {
    if (isBossPhase || currentBoss != null) return;
    
    isBossPhase = true;
    BossType bossType = BossType.values[(level - 1).clamp(0, 9)];
    currentBoss = Boss(x: 0.5, y: -0.15, type: bossType);
    
    // Clear remaining aliens for boss fight
    aliens.clear();
  }

  void _updateBoss(double dt) {
    if (currentBoss == null) return;
    var boss = currentBoss!;

    // Enter screen
    if (boss.y < 0.15) {
      boss.y += dt * 0.1;
      return;
    }

    // Check enraged state
    if (!boss.isEnraged && boss.hp <= boss.maxHp / 2) {
      boss.isEnraged = true;
    }

    // Movement pattern based on boss type
    boss.moveTimer += dt;
    double moveSpeed = boss.isEnraged ? 0.4 : 0.25;
    
    switch (boss.type) {
      case BossType.scout:
        boss.x += sin(boss.moveTimer * 3) * dt * moveSpeed;
        break;
      case BossType.phantom:
        // Teleport randomly
        if (_random.nextDouble() < dt * 0.5) {
          boss.x = 0.2 + _random.nextDouble() * 0.6;
        }
        break;
      case BossType.nemesis:
        // Mirror player X
        boss.x += (playerX - boss.x) * dt * 2;
        break;
      default:
        // Slow horizontal sweep
        boss.x += sin(boss.moveTimer * 1.5) * dt * moveSpeed * 0.5;
    }
    boss.x = boss.x.clamp(0.15, 0.85);

    // Shooting pattern
    boss.shootTimer -= dt;
    double fireRate = boss.isEnraged ? 0.3 : 0.5;
    
    if (boss.shootTimer <= 0) {
      _bossShoot(boss);
      boss.shootTimer = fireRate;
    }

    // Special attack for Carrier - spawn minions
    if (boss.type == BossType.carrier) {
      boss.phaseTimer -= dt;
      if (boss.phaseTimer <= 0 && aliens.length < 5) {
        aliens.add(Alien(x: boss.x, y: boss.y + 0.05, type: AlienType.fast, pattern: MovementPattern.straight));
        boss.phaseTimer = 3.0;
      }
    }
  }

  void _bossShoot(Boss boss) {
    switch (boss.type) {
      case BossType.scout:
        enemyBullets.add(Bullet(x: boss.x, y: boss.y + 0.08, isPlayerBullet: false));
        break;
      case BossType.destroyer:
        // Two cannons
        enemyBullets.add(Bullet(x: boss.x - 0.08, y: boss.y + 0.08, isPlayerBullet: false));
        enemyBullets.add(Bullet(x: boss.x + 0.08, y: boss.y + 0.08, isPlayerBullet: false));
        break;
      case BossType.hydra:
        // Triple spread
        for (int i = -1; i <= 1; i++) {
          enemyBullets.add(Bullet(x: boss.x + i * 0.05, y: boss.y + 0.08, isPlayerBullet: false));
        }
        break;
      case BossType.overlord:
        // Bullet hell - 5 bullets in arc
        for (int i = -2; i <= 2; i++) {
          enemyBullets.add(Bullet(x: boss.x + i * 0.04, y: boss.y + 0.06, isPlayerBullet: false));
        }
        break;
      default:
        enemyBullets.add(Bullet(x: boss.x, y: boss.y + 0.08, isPlayerBullet: false));
    }
  }

  void _updateAliens(double dt) {
    for (int i = aliens.length - 1; i >= 0; i--) {
      var alien = aliens[i];
      
      // Movement
      double speed = alien.type == AlienType.fast ? 0.4 : (alien.type == AlienType.boss ? 0.15 : 0.25);
      alien.y += dt * speed;

      // Pattern
      switch (alien.pattern) {
        case MovementPattern.straight:
          break;
        case MovementPattern.zigzag:
          alien.x += sin(alien.y * 10 + alien.phaseOffset) * dt * 0.5;
          break;
        case MovementPattern.sineWave:
          alien.x = alien.startX + sin(alien.y * 5 + alien.phaseOffset) * 0.15;
          break;
      }

      // Clamp X
      alien.x = alien.x.clamp(0.05, 0.95);

      // Shoot (only some aliens)
      if (alien.type != AlienType.basic) {
        alien.shootTimer -= dt;
        if (alien.shootTimer <= 0) {
          enemyBullets.add(Bullet(x: alien.x, y: alien.y + 0.05, isPlayerBullet: false));
          alien.shootTimer = alien.type == AlienType.boss ? 0.5 : 1.5;
        }
      }

      // Remove if off screen
      if (alien.y > 1.1) {
        aliens.removeAt(i);
      }
    }

    // Increase difficulty
    if (aliens.isEmpty && alienSpawnTimer > 0.5) {
      wave++;
      alienSpawnRate = max(0.5, alienSpawnRate - 0.1);
    }
  }

  void _updateParticles(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      var p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
      }
    }
  }

  void _updatePowerUps(double dt) {
    for (int i = powerUps.length - 1; i >= 0; i--) {
      powerUps[i].y += dt * 0.2;
      if (powerUps[i].y > 1.1) {
        powerUps.removeAt(i);
      }
    }
  }

  void _checkCollisions() {
    // Player Bullets vs Aliens
    for (int bi = playerBullets.length - 1; bi >= 0; bi--) {
      var bullet = playerBullets[bi];
      for (int ai = aliens.length - 1; ai >= 0; ai--) {
        var alien = aliens[ai];
        double hitRadius = alien.type == AlienType.tank ? 0.06 : 0.04;
        if ((bullet.x - alien.x).abs() < hitRadius && (bullet.y - alien.y).abs() < hitRadius) {
          // Hit!
          alien.hp--;
          playerBullets.removeAt(bi);
          _spawnExplosion(alien.x, alien.y, small: true);

          if (alien.hp <= 0) {
            aliens.removeAt(ai);
            _spawnExplosion(alien.x, alien.y, small: false);
            score += alien.type == AlienType.tank ? 30 : (alien.type == AlienType.fast ? 15 : 10);
            killsThisLevel++; // Track kills for boss spawn
            SoundService.playSuccess();

            // Maybe drop power-up
            if (_random.nextDouble() < 0.15) {
              powerUps.add(PowerUp(
                x: alien.x,
                y: alien.y,
                type: PowerUpType.values[_random.nextInt(PowerUpType.values.length)],
              ));
            }
          }
          break;
        }
      }
    }

    // Player Bullets vs Boss
    if (currentBoss != null) {
      var boss = currentBoss!;
      // Boss hit radius scales with level (bigger bosses = bigger hitbox)
      double bossHitRadius = 0.10 + (level * 0.015);
      for (int bi = playerBullets.length - 1; bi >= 0; bi--) {
        var bullet = playerBullets[bi];
        if ((bullet.x - boss.x).abs() < bossHitRadius && (bullet.y - boss.y).abs() < bossHitRadius) {
          boss.hp--;
          playerBullets.removeAt(bi);
          _spawnExplosion(bullet.x, bullet.y, small: true);

          if (boss.hp <= 0) {
            // Boss defeated!
            _spawnExplosion(boss.x, boss.y, small: false);
            _spawnExplosion(boss.x - 0.1, boss.y, small: false);
            _spawnExplosion(boss.x + 0.1, boss.y, small: false);
            score += 100 * level;
            SoundService.playSuccess();
            
            // Level up!
            _levelUp();
          }
        }
      }
    }

    // Enemy Bullets vs Player
    double playerY = 0.9;
    for (int i = enemyBullets.length - 1; i >= 0; i--) {
      var bullet = enemyBullets[i];
      if ((bullet.x - playerX).abs() < 0.04 && (bullet.y - playerY).abs() < 0.04) {
        enemyBullets.removeAt(i);
        _playerHit();
      }
    }

    // Aliens vs Player
    for (var alien in aliens) {
      if ((alien.x - playerX).abs() < 0.05 && (alien.y - playerY).abs() < 0.05) {
        _playerHit();
      }
    }

    // Boss vs Player
    if (currentBoss != null) {
      var boss = currentBoss!;
      if ((boss.x - playerX).abs() < 0.1 && (boss.y - playerY).abs() < 0.1) {
        _playerHit();
      }
    }

    // PowerUps vs Player
    for (int i = powerUps.length - 1; i >= 0; i--) {
      var pu = powerUps[i];
      if ((pu.x - playerX).abs() < 0.05 && (pu.y - playerY).abs() < 0.05) {
        _collectPowerUp(pu);
        powerUps.removeAt(i);
      }
    }
  }

  void _levelUp() {
    currentBoss = null;
    isBossPhase = false;
    killsThisLevel = 0;
    
    // Clear all enemy bullets for fresh level start
    enemyBullets.clear();
    
    if (level >= 10) {
      // Game Complete - VICTORY!
      isGameOver = true;
      isVictory = true;
      isPlaying = false;
      _saveHighScore();
    } else {
      level++;
      wave = 1;
      killsToSpawnBoss = 15 + (level * 5); // More kills needed for higher levels
      alienSpawnRate = max(0.5, 2.0 - level * 0.1); // Faster spawns
      
      // Bonus life every few levels
      if (level % 3 == 0) {
        lives = min(lives + 1, 5);
      }
    }
  }

  void _playerHit() {
    if (hasShield) {
      hasShield = false;
      return;
    }
    lives--;
    _spawnExplosion(playerX, 0.9, small: false);
    SoundService.playFail();
    if (lives <= 0) {
      isGameOver = true;
      isPlaying = false;
      _saveHighScore();
    }
  }

  Future<void> _saveHighScore() async {
    isNewHighScore = await HighScoreService.setHighScore(HighScoreService.spaceShooter, score);
    highScore = HighScoreService.getHighScore(HighScoreService.spaceShooter);
  }

  void _collectPowerUp(PowerUp pu) {
    switch (pu.type) {
      case PowerUpType.doubleShot:
        hasDoubleShot = true;
        break;
      case PowerUpType.shield:
        hasShield = true;
        shieldTime = 5.0;
        break;
      case PowerUpType.life:
        lives = min(lives + 1, 5);
        break;
    }
    SoundService.playSuccess();
  }

  void _spawnExplosion(double x, double y, {required bool small}) {
    int count = small ? 5 : 12;
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * pi * 2;
      double speed = 0.2 + _random.nextDouble() * 0.3;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.3 + _random.nextDouble() * 0.3,
        color: small ? Colors.orange : Colors.yellow,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: (d) {
          if (isPlaying && !isGameOver) {
            setState(() {
              playerX += d.delta.dx / screenSize.width;
              playerX = playerX.clamp(0.05, 0.95);
            });
          }
        },
        child: CustomPaint(
          painter: SpaceShooterPainter(
            stars: stars,
            playerX: playerX,
            playerBullets: playerBullets,
            enemyBullets: enemyBullets,
            aliens: aliens,
            particles: particles,
            powerUps: powerUps,
            hasShield: hasShield,
            currentBoss: currentBoss,
            level: level,
          ),
          child: SizedBox.expand(
            child: Stack(
              children: [
                // HUD
                if (isPlaying && !isGameOver) _buildHUD(),
                
                // Overlays
                if (!isPlaying || isGameOver) _buildOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lives
                Row(
                  children: List.generate(lives, (i) => const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.favorite, color: Colors.red, size: 20),
                  )),
                ),
                // Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(150),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LEVEL $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Score
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGameOver ? (isVictory ? '🎉 VICTORY! 🎉' : 'GAME OVER') : 'SPACE IMPACT',
              style: TextStyle(
                color: isVictory ? Colors.amber : Colors.green,
                fontSize: 28,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isGameOver) ...[
              const SizedBox(height: 10),
              if (isVictory)
                const Text(
                  'You defeated all 10 bosses!',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 16),
                ),
              if (isNewHighScore)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🏆 NEW HIGH SCORE! 🏆',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 5),
              Text(
                'Final Score: $score',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                'High Score: $highScore',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                isGameOver ? 'RETRY' : 'START',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.spaceShooter),
              icon: AppIcons.help(color: Colors.white70),
              label: const Text('How to Play', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Painter ---

class SpaceShooterPainter extends CustomPainter {
  final List<Star> stars;
  final double playerX;
  final List<Bullet> playerBullets;
  final List<Bullet> enemyBullets;
  final List<Alien> aliens;
  final List<Particle> particles;
  final List<PowerUp> powerUps;
  final bool hasShield;
  final Boss? currentBoss;
  final int level;

  SpaceShooterPainter({
    required this.stars,
    required this.playerX,
    required this.playerBullets,
    required this.enemyBullets,
    required this.aliens,
    required this.particles,
    required this.powerUps,
    required this.hasShield,
    required this.currentBoss,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Stars
    final starPaint = Paint()..color = Colors.white;
    for (var star in stars) {
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        starPaint,
      );
    }

    // Player
    _drawPlayer(canvas, size);

    // Player Bullets
    final bulletPaint = Paint()..color = Colors.cyanAccent;
    for (var b in playerBullets) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(b.x * size.width, b.y * size.height),
          width: 4,
          height: 12,
        ),
        bulletPaint,
      );
    }

    // Enemy Bullets
    final enemyBulletPaint = Paint()..color = Colors.redAccent;
    for (var b in enemyBullets) {
      canvas.drawCircle(
        Offset(b.x * size.width, b.y * size.height),
        5,
        enemyBulletPaint,
      );
    }

    // Aliens
    for (var alien in aliens) {
      _drawAlien(canvas, size, alien);
    }

    // Boss
    if (currentBoss != null) {
      _drawBoss(canvas, size, currentBoss!);
    }

    // Particles
    for (var p in particles) {
      final particlePaint = Paint()..color = p.color.withAlpha((p.life * 255).toInt().clamp(0, 255));
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        3,
        particlePaint,
      );
    }

    // PowerUps
    for (var pu in powerUps) {
      _drawPowerUp(canvas, size, pu);
    }
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final x = playerX * size.width;
    final y = size.height * 0.9;
    final paint = Paint();

    // Engine flame trail (animated effect using level for pseudo-animation)
    paint.color = Colors.orange.withAlpha(180);
    Path flame1 = Path();
    flame1.moveTo(x - 5, y + 10);
    flame1.lineTo(x, y + 25 + (level % 2) * 5);
    flame1.lineTo(x + 5, y + 10);
    flame1.close();
    canvas.drawPath(flame1, paint);
    
    paint.color = Colors.yellow.withAlpha(200);
    Path flame2 = Path();
    flame2.moveTo(x - 3, y + 10);
    flame2.lineTo(x, y + 18 + (level % 2) * 3);
    flame2.lineTo(x + 3, y + 10);
    flame2.close();
    canvas.drawPath(flame2, paint);

    // Outer glow
    paint.color = Colors.greenAccent.withAlpha(50);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(x, y - 5), 22, paint);
    paint.maskFilter = null;

    // Wings
    paint.color = Colors.green[700]!;
    Path leftWing = Path();
    leftWing.moveTo(x - 8, y);
    leftWing.lineTo(x - 25, y + 5);
    leftWing.lineTo(x - 20, y + 12);
    leftWing.lineTo(x - 8, y + 8);
    leftWing.close();
    canvas.drawPath(leftWing, paint);

    Path rightWing = Path();
    rightWing.moveTo(x + 8, y);
    rightWing.lineTo(x + 25, y + 5);
    rightWing.lineTo(x + 20, y + 12);
    rightWing.lineTo(x + 8, y + 8);
    rightWing.close();
    canvas.drawPath(rightWing, paint);

    // Main body
    paint.color = Colors.green;
    Path ship = Path();
    ship.moveTo(x, y - 22); // Nose
    ship.lineTo(x - 12, y + 8); // Bottom left
    ship.lineTo(x, y + 4); // Center bottom
    ship.lineTo(x + 12, y + 8); // Bottom right
    ship.close();
    canvas.drawPath(ship, paint);

    // Body detail stripe
    paint.color = Colors.green[800]!;
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 5), width: 6, height: 16), paint);

    // Cockpit (glowing)
    paint.color = Colors.lightGreenAccent;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 8), width: 8, height: 10), paint);
    paint.color = Colors.white.withAlpha(180);
    canvas.drawCircle(Offset(x, y - 9), 2, paint);

    // Wing tips
    paint.color = Colors.redAccent;
    canvas.drawCircle(Offset(x - 22, y + 8), 3, paint);
    canvas.drawCircle(Offset(x + 22, y + 8), 3, paint);

    // Shield
    if (hasShield) {
      paint.color = Colors.cyanAccent.withAlpha(80);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 30, paint);
      paint.color = Colors.cyanAccent;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 30, paint);
    }
  }

  void _drawAlien(Canvas canvas, Size size, Alien alien) {
    final x = alien.x * size.width;
    final y = alien.y * size.height;
    final paint = Paint();

    switch (alien.type) {
      case AlienType.basic:
        // UFO-style saucer
        paint.color = Colors.purple;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 28, height: 10), paint);
        paint.color = Colors.purpleAccent;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 4), width: 16, height: 10), paint);
        // Lights
        paint.color = Colors.yellow;
        canvas.drawCircle(Offset(x - 8, y), 2, paint);
        canvas.drawCircle(Offset(x, y), 2, paint);
        canvas.drawCircle(Offset(x + 8, y), 2, paint);
        break;
        
      case AlienType.fast:
        // Sleek fighter
        paint.color = Colors.orange;
        Path fighter = Path();
        fighter.moveTo(x, y - 12); // Nose
        fighter.lineTo(x - 10, y + 8);
        fighter.lineTo(x - 4, y + 4);
        fighter.lineTo(x, y + 10);
        fighter.lineTo(x + 4, y + 4);
        fighter.lineTo(x + 10, y + 8);
        fighter.close();
        canvas.drawPath(fighter, paint);
        // Engine glow
        paint.color = Colors.yellow.withAlpha(200);
        canvas.drawCircle(Offset(x, y + 8), 3, paint);
        break;
        
      case AlienType.tank:
        // Heavy cruiser
        paint.color = Colors.blueGrey[700]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 30, height: 22),
            const Radius.circular(4),
          ),
          paint,
        );
        // Armor plates
        paint.color = Colors.blueGrey[400]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 8, y), width: 6, height: 18), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 8, y), width: 6, height: 18), paint);
        // Cannon
        paint.color = Colors.red[900]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 10), width: 8, height: 6), paint);
        break;
        
      case AlienType.boss:
        // Mothership
        // Main hull
        paint.color = Colors.red[900]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 70, height: 35), paint);
        // Details
        paint.color = Colors.red[700]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 5), width: 50, height: 20), paint);
        // Bridge
        paint.color = Colors.grey[800]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 8), width: 20, height: 12), paint);
        // Eyes
        paint.color = Colors.yellow;
        canvas.drawCircle(Offset(x - 6, y - 8), 4, paint);
        canvas.drawCircle(Offset(x + 6, y - 8), 4, paint);
        // Weapon ports
        paint.color = Colors.orange;
        canvas.drawCircle(Offset(x - 25, y + 5), 4, paint);
        canvas.drawCircle(Offset(x + 25, y + 5), 4, paint);
        canvas.drawCircle(Offset(x, y + 12), 5, paint);
        // HP bar
        paint.color = Colors.grey[900]!;
        canvas.drawRect(Rect.fromLTWH(x - 30, y - 25, 60, 6), paint);
        paint.color = Colors.greenAccent;
        double hpPercent = alien.hp / 10.0;
        canvas.drawRect(Rect.fromLTWH(x - 30, y - 25, 60 * hpPercent, 6), paint);
        break;
    }
  }

  void _drawBoss(Canvas canvas, Size size, Boss boss) {
    final x = boss.x * size.width;
    final y = boss.y * size.height;
    final paint = Paint();
    
    // Level-based size scaling (bosses get bigger each level)
    double levelScale = 0.8 + (level * 0.12); // Level 1 = 0.92, Level 10 = 2.0
    double scale = levelScale;

    // --- OUTER GLOW (all bosses) ---
    Color glowColor = boss.isEnraged ? Colors.red : _getBossGlowColor(boss.type);
    paint.color = glowColor.withAlpha(70);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(x, y), 40 * scale, paint);
    paint.maskFilter = null;

    // --- FLAME TRAIL (all bosses have engine fire) ---
    _drawBossFlame(canvas, x, y, scale, boss.type);

    // --- MAIN BODY (type-specific) ---
    switch (boss.type) {
      case BossType.scout:
        // Fast interceptor
        paint.color = Colors.teal[700]!;
        Path body = Path();
        body.moveTo(x, y - 22 * scale);
        body.lineTo(x - 28 * scale, y + 14 * scale);
        body.lineTo(x, y + 8 * scale);
        body.lineTo(x + 28 * scale, y + 14 * scale);
        body.close();
        canvas.drawPath(body, paint);
        // Wings
        paint.color = Colors.teal[500]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 18 * scale, y + 5 * scale), width: 8 * scale, height: 18 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 18 * scale, y + 5 * scale), width: 8 * scale, height: 18 * scale), paint);
        // Cockpit
        paint.color = Colors.tealAccent;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 8 * scale), width: 10 * scale, height: 14 * scale), paint);
        paint.color = Colors.white.withAlpha(200);
        canvas.drawCircle(Offset(x, y - 10 * scale), 3 * scale, paint);
        // Wing tips
        paint.color = Colors.orangeAccent;
        canvas.drawCircle(Offset(x - 22 * scale, y + 12 * scale), 4 * scale, paint);
        canvas.drawCircle(Offset(x + 22 * scale, y + 12 * scale), 4 * scale, paint);
        break;

      case BossType.cruiser:
        // Balanced cruiser
        paint.color = Colors.indigo[700]!;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 60 * scale, height: 30 * scale),
          Radius.circular(10 * scale),
        ), paint);
        // Body stripe
        paint.color = Colors.indigo[400]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 50 * scale, height: 6 * scale), paint);
        // Wings
        paint.color = Colors.indigo[800]!;
        Path leftWing = Path();
        leftWing.moveTo(x - 25 * scale, y - 5 * scale);
        leftWing.lineTo(x - 40 * scale, y);
        leftWing.lineTo(x - 35 * scale, y + 12 * scale);
        leftWing.lineTo(x - 25 * scale, y + 10 * scale);
        leftWing.close();
        canvas.drawPath(leftWing, paint);
        Path rightWing = Path();
        rightWing.moveTo(x + 25 * scale, y - 5 * scale);
        rightWing.lineTo(x + 40 * scale, y);
        rightWing.lineTo(x + 35 * scale, y + 12 * scale);
        rightWing.lineTo(x + 25 * scale, y + 10 * scale);
        rightWing.close();
        canvas.drawPath(rightWing, paint);
        // Cockpit
        paint.color = Colors.indigoAccent;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 5 * scale), width: 14 * scale, height: 10 * scale), paint);
        paint.color = Colors.white.withAlpha(180);
        canvas.drawCircle(Offset(x, y - 6 * scale), 3 * scale, paint);
        // Wing tips
        paint.color = Colors.redAccent;
        canvas.drawCircle(Offset(x - 38 * scale, y + 6 * scale), 4 * scale, paint);
        canvas.drawCircle(Offset(x + 38 * scale, y + 6 * scale), 4 * scale, paint);
        break;

      case BossType.destroyer:
        // Twin cannon warship
        paint.color = Colors.grey[800]!;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 70 * scale, height: 35 * scale),
          Radius.circular(6 * scale),
        ), paint);
        // Body stripe
        paint.color = Colors.grey[600]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 8 * scale), width: 60 * scale, height: 5 * scale), paint);
        // Twin cannons (iconic feature)
        paint.color = Colors.red[800]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 25 * scale, y + 15 * scale), width: 10 * scale, height: 18 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 25 * scale, y + 15 * scale), width: 10 * scale, height: 18 * scale), paint);
        // Cannon glow
        paint.color = Colors.orange;
        canvas.drawCircle(Offset(x - 25 * scale, y + 22 * scale), 4 * scale, paint);
        canvas.drawCircle(Offset(x + 25 * scale, y + 22 * scale), 4 * scale, paint);
        // Cockpit
        paint.color = Colors.amber;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 5 * scale), width: 12 * scale, height: 10 * scale), paint);
        break;

      case BossType.carrier:
        // Hangar ship that spawns minions
        paint.color = Colors.brown[800]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 80 * scale, height: 40 * scale), paint);
        // Deck
        paint.color = Colors.brown[600]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 50 * scale, height: 25 * scale), paint);
        // Body stripe
        paint.color = Colors.brown[400]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 70 * scale, height: 5 * scale), paint);
        // Hangar bay (glowing)
        paint.color = Colors.yellowAccent.withAlpha(150);
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 12 * scale), width: 25 * scale, height: 12 * scale), paint);
        // Cockpit
        paint.color = Colors.orangeAccent;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 10 * scale), width: 14 * scale, height: 8 * scale), paint);
        break;

      case BossType.dreadnought:
        // Heavy armored fortress
        paint.color = Colors.blueGrey[900]!;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 90 * scale, height: 45 * scale),
          Radius.circular(8 * scale),
        ), paint);
        // Armor layers
        paint.color = Colors.blueGrey[700]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 12 * scale), width: 80 * scale, height: 8 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 12 * scale), width: 80 * scale, height: 8 * scale), paint);
        // Body stripe
        paint.color = Colors.blueGrey[500]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 6 * scale, height: 35 * scale), paint);
        // Turrets
        paint.color = Colors.red[900]!;
        canvas.drawCircle(Offset(x - 30 * scale, y), 8 * scale, paint);
        canvas.drawCircle(Offset(x + 30 * scale, y), 8 * scale, paint);
        // Cockpit
        paint.color = Colors.cyanAccent;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 8 * scale), width: 16 * scale, height: 10 * scale), paint);
        break;

      case BossType.phantom:
        // Ghostly teleporter
        paint.color = Colors.deepPurple.withAlpha(200);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 65 * scale, height: 35 * scale), paint);
        // Inner glow
        paint.color = Colors.white.withAlpha(80);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 45 * scale, height: 22 * scale), paint);
        // Ghostly wings
        paint.color = Colors.purple.withAlpha(120);
        Path ghost1 = Path();
        ghost1.moveTo(x - 25 * scale, y);
        ghost1.quadraticBezierTo(x - 50 * scale, y - 15 * scale, x - 35 * scale, y + 20 * scale);
        ghost1.lineTo(x - 25 * scale, y + 10 * scale);
        ghost1.close();
        canvas.drawPath(ghost1, paint);
        Path ghost2 = Path();
        ghost2.moveTo(x + 25 * scale, y);
        ghost2.quadraticBezierTo(x + 50 * scale, y - 15 * scale, x + 35 * scale, y + 20 * scale);
        ghost2.lineTo(x + 25 * scale, y + 10 * scale);
        ghost2.close();
        canvas.drawPath(ghost2, paint);
        // Glowing eyes
        paint.color = Colors.pinkAccent;
        canvas.drawCircle(Offset(x - 12 * scale, y - 5 * scale), 6 * scale, paint);
        canvas.drawCircle(Offset(x + 12 * scale, y - 5 * scale), 6 * scale, paint);
        paint.color = Colors.white;
        canvas.drawCircle(Offset(x - 12 * scale, y - 6 * scale), 2 * scale, paint);
        canvas.drawCircle(Offset(x + 12 * scale, y - 6 * scale), 2 * scale, paint);
        break;

      case BossType.hydra:
        // Three-headed beast
        paint.color = Colors.green[800]!;
        // Main body
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 5 * scale), width: 60 * scale, height: 35 * scale), paint);
        // Body stripe
        paint.color = Colors.green[600]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 5 * scale), width: 50 * scale, height: 6 * scale), paint);
        // Three heads with necks
        for (int i = -1; i <= 1; i++) {
          double headX = x + i * 25 * scale;
          // Neck
          paint.color = Colors.green[700]!;
          canvas.drawRect(Rect.fromCenter(center: Offset(headX, y - 10 * scale), width: 8 * scale, height: 20 * scale), paint);
          // Head
          paint.color = Colors.green[800]!;
          canvas.drawCircle(Offset(headX, y - 22 * scale), 12 * scale, paint);
          // Eye
          paint.color = Colors.red;
          canvas.drawCircle(Offset(headX, y - 24 * scale), 5 * scale, paint);
          paint.color = Colors.yellow;
          canvas.drawCircle(Offset(headX, y - 25 * scale), 2 * scale, paint);
        }
        break;

      case BossType.titan:
        // Massive slow giant
        paint.color = Colors.grey[700]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 110 * scale, height: 55 * scale), paint);
        // Upper deck
        paint.color = Colors.grey[500]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 12 * scale), width: 70 * scale, height: 28 * scale), paint);
        // Body stripes
        paint.color = Colors.grey[400]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 25 * scale, y), width: 6 * scale, height: 40 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 25 * scale, y), width: 6 * scale, height: 40 * scale), paint);
        // Turret array (5 guns)
        paint.color = Colors.red[800]!;
        for (double dx = -40; dx <= 40; dx += 20) {
          canvas.drawCircle(Offset(x + dx * scale, y + 18 * scale), 7 * scale, paint);
          paint.color = Colors.orange;
          canvas.drawCircle(Offset(x + dx * scale, y + 22 * scale), 3 * scale, paint);
          paint.color = Colors.red[800]!;
        }
        // Bridge (cockpit)
        paint.color = Colors.amber;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 15 * scale), width: 20 * scale, height: 12 * scale), paint);
        break;

      case BossType.nemesis:
        // Evil mirror of player
        // Wings
        paint.color = Colors.red[800]!;
        Path leftWing = Path();
        leftWing.moveTo(x - 10 * scale, y);
        leftWing.lineTo(x - 35 * scale, y + 8 * scale);
        leftWing.lineTo(x - 28 * scale, y + 18 * scale);
        leftWing.lineTo(x - 10 * scale, y + 12 * scale);
        leftWing.close();
        canvas.drawPath(leftWing, paint);
        Path rightWing = Path();
        rightWing.moveTo(x + 10 * scale, y);
        rightWing.lineTo(x + 35 * scale, y + 8 * scale);
        rightWing.lineTo(x + 28 * scale, y + 18 * scale);
        rightWing.lineTo(x + 10 * scale, y + 12 * scale);
        rightWing.close();
        canvas.drawPath(rightWing, paint);
        // Main body
        paint.color = Colors.red[900]!;
        Path body = Path();
        body.moveTo(x, y - 28 * scale);
        body.lineTo(x - 16 * scale, y + 14 * scale);
        body.lineTo(x, y + 8 * scale);
        body.lineTo(x + 16 * scale, y + 14 * scale);
        body.close();
        canvas.drawPath(body, paint);
        // Body stripe
        paint.color = Colors.red[700]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 5 * scale), width: 6 * scale, height: 22 * scale), paint);
        // Cockpit (evil glow)
        paint.color = Colors.orange;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 10 * scale), width: 10 * scale, height: 14 * scale), paint);
        paint.color = Colors.yellow;
        canvas.drawCircle(Offset(x, y - 12 * scale), 3 * scale, paint);
        // Wing tips
        paint.color = Colors.orangeAccent;
        canvas.drawCircle(Offset(x - 32 * scale, y + 12 * scale), 4 * scale, paint);
        canvas.drawCircle(Offset(x + 32 * scale, y + 12 * scale), 4 * scale, paint);
        break;

      case BossType.overlord:
        // Final boss - ultimate form
        // Outer hull
        paint.color = Colors.black;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 130 * scale, height: 65 * scale), paint);
        // Inner hull
        paint.color = Colors.red[900]!;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 110 * scale, height: 50 * scale), paint);
        // Body stripes
        paint.color = Colors.red[700]!;
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 30 * scale, y), width: 6 * scale, height: 45 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 30 * scale, y), width: 6 * scale, height: 45 * scale), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 100 * scale, height: 6 * scale), paint);
        // Core (glowing)
        paint.color = Colors.yellow;
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(x, y), 20 * scale, paint);
        paint.maskFilter = null;
        paint.color = Colors.orange;
        canvas.drawCircle(Offset(x, y), 12 * scale, paint);
        paint.color = Colors.white;
        canvas.drawCircle(Offset(x, y), 5 * scale, paint);
        // Weapon array (7 cannons)
        paint.color = Colors.cyanAccent;
        for (int i = -3; i <= 3; i++) {
          canvas.drawCircle(Offset(x + i * 16 * scale, y + 25 * scale), 6 * scale, paint);
        }
        // Wings
        paint.color = Colors.red[800]!;
        Path lw = Path();
        lw.moveTo(x - 50 * scale, y - 10 * scale);
        lw.lineTo(x - 70 * scale, y);
        lw.lineTo(x - 60 * scale, y + 20 * scale);
        lw.lineTo(x - 50 * scale, y + 15 * scale);
        lw.close();
        canvas.drawPath(lw, paint);
        Path rw = Path();
        rw.moveTo(x + 50 * scale, y - 10 * scale);
        rw.lineTo(x + 70 * scale, y);
        rw.lineTo(x + 60 * scale, y + 20 * scale);
        rw.lineTo(x + 50 * scale, y + 15 * scale);
        rw.close();
        canvas.drawPath(rw, paint);
        // Wing tips
        paint.color = Colors.pinkAccent;
        canvas.drawCircle(Offset(x - 65 * scale, y + 10 * scale), 5 * scale, paint);
        canvas.drawCircle(Offset(x + 65 * scale, y + 10 * scale), 5 * scale, paint);
        break;
    }

    // --- HP BAR ---
    double barWidth = 70 * scale;
    paint.color = Colors.grey[900]!;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x - barWidth / 2, y - 40 * scale, barWidth, 8),
      const Radius.circular(4),
    ), paint);
    paint.color = boss.isEnraged ? Colors.redAccent : Colors.greenAccent;
    double hpPercent = boss.hp / boss.maxHp;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x - barWidth / 2, y - 40 * scale, barWidth * hpPercent, 8),
      const Radius.circular(4),
    ), paint);
  }

  Color _getBossGlowColor(BossType type) {
    switch (type) {
      case BossType.scout: return Colors.teal;
      case BossType.cruiser: return Colors.indigo;
      case BossType.destroyer: return Colors.grey;
      case BossType.carrier: return Colors.brown;
      case BossType.dreadnought: return Colors.blueGrey;
      case BossType.phantom: return Colors.purple;
      case BossType.hydra: return Colors.green;
      case BossType.titan: return Colors.grey;
      case BossType.nemesis: return Colors.red;
      case BossType.overlord: return Colors.orange;
    }
  }

  void _drawBossFlame(Canvas canvas, double x, double y, double scale, BossType type) {
    final paint = Paint();
    // Engine positions vary by boss type
    List<Offset> engines = [];
    switch (type) {
      case BossType.scout:
        engines = [Offset(x - 12 * scale, y + 14 * scale), Offset(x + 12 * scale, y + 14 * scale)];
        break;
      case BossType.cruiser:
        engines = [Offset(x - 20 * scale, y + 15 * scale), Offset(x + 20 * scale, y + 15 * scale)];
        break;
      case BossType.destroyer:
        engines = [Offset(x - 15 * scale, y + 18 * scale), Offset(x + 15 * scale, y + 18 * scale)];
        break;
      case BossType.overlord:
        engines = [Offset(x - 40 * scale, y + 25 * scale), Offset(x, y + 30 * scale), Offset(x + 40 * scale, y + 25 * scale)];
        break;
      default:
        engines = [Offset(x, y + 20 * scale)];
    }
    
    for (var eng in engines) {
      // Outer flame
      paint.color = Colors.orange.withAlpha(180);
      Path flame = Path();
      flame.moveTo(eng.dx - 6 * scale, eng.dy);
      flame.lineTo(eng.dx, eng.dy + 25 * scale);
      flame.lineTo(eng.dx + 6 * scale, eng.dy);
      flame.close();
      canvas.drawPath(flame, paint);
      // Inner flame
      paint.color = Colors.yellow.withAlpha(220);
      Path inner = Path();
      inner.moveTo(eng.dx - 3 * scale, eng.dy);
      inner.lineTo(eng.dx, eng.dy + 15 * scale);
      inner.lineTo(eng.dx + 3 * scale, eng.dy);
      inner.close();
      canvas.drawPath(inner, paint);
    }
  }

  void _drawPowerUp(Canvas canvas, Size size, PowerUp pu) {
    final x = pu.x * size.width;
    final y = pu.y * size.height;
    final paint = Paint();

    // Outer glow for all power-ups
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    switch (pu.type) {
      case PowerUpType.doubleShot:
        // Weapon upgrade - glowing ammo box
        paint.color = Colors.yellow.withAlpha(100);
        canvas.drawCircle(Offset(x, y), 18, paint);
        paint.maskFilter = null;
        paint.color = Colors.amber[700]!;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 20, height: 20),
          const Radius.circular(4),
        ), paint);
        paint.color = Colors.yellow;
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y - 3), width: 4, height: 10), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 5, y - 3), width: 4, height: 10), paint);
        canvas.drawRect(Rect.fromCenter(center: Offset(x - 5, y - 3), width: 4, height: 10), paint);
        break;
        
      case PowerUpType.shield:
        // Energy shield
        paint.color = Colors.cyanAccent.withAlpha(100);
        canvas.drawCircle(Offset(x, y), 18, paint);
        paint.maskFilter = null;
        paint.color = Colors.cyan[700]!;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 4;
        canvas.drawCircle(Offset(x, y), 12, paint);
        paint.style = PaintingStyle.fill;
        paint.color = Colors.cyanAccent;
        canvas.drawCircle(Offset(x, y), 6, paint);
        paint.color = Colors.white;
        canvas.drawCircle(Offset(x - 2, y - 2), 2, paint);
        break;
        
      case PowerUpType.life:
        // Glowing heart
        paint.color = Colors.red.withAlpha(100);
        canvas.drawCircle(Offset(x, y), 18, paint);
        paint.maskFilter = null;
        paint.color = Colors.red[700]!;
        Path heart = Path();
        heart.moveTo(x, y + 8);
        heart.cubicTo(x - 14, y - 4, x - 14, y - 18, x, y - 10);
        heart.cubicTo(x + 14, y - 18, x + 14, y - 4, x, y + 8);
        canvas.drawPath(heart, paint);
        // Shine
        paint.color = Colors.white.withAlpha(150);
        canvas.drawCircle(Offset(x - 4, y - 8), 3, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(SpaceShooterPainter oldDelegate) => true;
}

// --- Data Classes ---

class Star {
  double x, y, speed, size;
  Star({required this.x, required this.y, required this.speed, required this.size});
}

class Bullet {
  double x, y;
  bool isPlayerBullet;
  Bullet({required this.x, required this.y, required this.isPlayerBullet});
}

enum AlienType { basic, fast, tank, boss }
enum MovementPattern { straight, zigzag, sineWave }

class Alien {
  double x, y;
  double startX;
  AlienType type;
  MovementPattern pattern;
  double phaseOffset;
  int hp;
  double shootTimer = 1.0;

  Alien({
    required this.x,
    required this.y,
    required this.type,
    required this.pattern,
    this.phaseOffset = 0,
  }) : startX = x,
       hp = type == AlienType.boss ? 10 : (type == AlienType.tank ? 3 : 1);
}

class Particle {
  double x, y, vx, vy, life;
  Color color;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.color});
}

enum PowerUpType { doubleShot, shield, life }

class PowerUp {
  double x, y;
  PowerUpType type;
  PowerUp({required this.x, required this.y, required this.type});
}

// 10 Unique Boss Types
enum BossType {
  scout,      // Level 1 - Small, fast, weak
  cruiser,    // Level 2 - Medium, balanced
  destroyer,  // Level 3 - Two cannons
  carrier,    // Level 4 - Spawns minions
  dreadnought,// Level 5 - Heavy armor
  phantom,    // Level 6 - Teleports
  hydra,      // Level 7 - Multi-head
  titan,      // Level 8 - Huge, slow
  nemesis,    // Level 9 - Mirror your moves
  overlord,   // Level 10 - Final boss, all attacks
}

class Boss {
  double x, y;
  BossType type;
  int hp;
  int maxHp;
  double shootTimer = 0;
  double moveTimer = 0;
  double phaseTimer = 0; // For special attacks
  bool isEnraged = false; // Below 50% HP

  Boss({required this.x, required this.y, required this.type})
      : maxHp = _getMaxHp(type),
        hp = _getMaxHp(type);

  static int _getMaxHp(BossType type) {
    switch (type) {
      case BossType.scout: return 20;
      case BossType.cruiser: return 35;
      case BossType.destroyer: return 50;
      case BossType.carrier: return 40;
      case BossType.dreadnought: return 80;
      case BossType.phantom: return 45;
      case BossType.hydra: return 70;
      case BossType.titan: return 120;
      case BossType.nemesis: return 60;
      case BossType.overlord: return 200;
    }
  }
}
