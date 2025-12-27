import 'package:flutter/material.dart';
import '../services/player_stats_service.dart';
import '../services/high_score_service.dart';
import '../widgets/app_icons.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  // Multiplayer/VS CPU games
  final List<GameStatData> multiplayerGames = [
    GameStatData('Tic Tac Toe', 'tag', PlayerStatsService.ticTacToe, const Color(0xFF667EEA)),
    GameStatData('Connect Four', 'connect-four', PlayerStatsService.connectFour, const Color(0xFF1565C0)),
    GameStatData('Snake & Ladder', 'snake', PlayerStatsService.snakeLadder, const Color(0xFF43A047)),
    GameStatData('Memory Match', 'brain', PlayerStatsService.memoryMatch, const Color(0xFFE91E63)),
    GameStatData('Ludo', 'dice', PlayerStatsService.ludo, const Color(0xFFFF8C42)),
    GameStatData('Dots & Boxes', 'grid', PlayerStatsService.dotsBoxes, const Color(0xFF9C27B0)),
    GameStatData('Simon Says', 'psychology', PlayerStatsService.simonSays, const Color(0xFF00BCD4)),
    GameStatData('Reaction Game', 'flash', PlayerStatsService.reactionGame, const Color(0xFFFF5722)),
    GameStatData('Number Guess', 'target', PlayerStatsService.numberGuess, const Color(0xFF795548)),
  ];

  // Solo high score games
  final List<HighScoreGameData> soloGames = [
    HighScoreGameData('Space Shooter', 'rocket', HighScoreService.spaceShooter, const Color(0xFF1A1A2E)),
    HighScoreGameData('Tetris', 'tetris', HighScoreService.tetris, const Color(0xFF00CED1)),
    HighScoreGameData('Arkanoid', 'brick', HighScoreService.arkanoid, const Color(0xFFFF6B6B)),
    HighScoreGameData('Candy Crush', 'candy', HighScoreService.candyCrush, const Color(0xFFFF6B9D)),
    HighScoreGameData('Bounce Tales', 'circle', HighScoreService.bounceTales, const Color(0xFFE53935)),
    HighScoreGameData('Diamond Rush', 'diamond', HighScoreService.diamondRush, const Color(0xFF00D9FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.back(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Stats',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Stats Card
            _buildOverallStatsCard(),
            const SizedBox(height: 25),
            
            // Section Title - Multiplayer/VS CPU
            Row(
              children: [
                AppIcons.svg('gamepad', size: 24, color: textDark),
                const SizedBox(width: 10),
                const Text(
                  'Multiplayer Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Multiplayer Game Stats Cards
            ...multiplayerGames.map((game) => _buildGameStatCard(game)),
            
            const SizedBox(height: 25),
            
            // Section Title - High Scores
            Row(
              children: [
                AppIcons.trophy(size: 24, color: const Color(0xFFFFD700)),
                const SizedBox(width: 10),
                const Text(
                  'High Scores',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // High Score Game Cards
            ...soloGames.map((game) => _buildHighScoreCard(game)),
            
            const SizedBox(height: 20),
            
            // Reset Button
            Center(
              child: OutlinedButton.icon(
                onPressed: _showResetConfirmation,
                icon: AppIcons.refresh(size: 18),
                label: const Text('Reset All Stats'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsCard() {
    final totalWins = playerStats.getTotalWins();
    final totalGames = playerStats.getTotalGamesPlayed();
    final winRate = totalGames > 0 ? (totalWins / totalGames * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcons.trophy(size: 40, color: Colors.amber),
              const SizedBox(width: 12),
              const Text(
                'Overall Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Total Wins', '$totalWins', Colors.greenAccent),
              Container(width: 1, height: 50, color: Colors.white24),
              _buildStatColumn('Games Played', '$totalGames', Colors.white),
              Container(width: 1, height: 50, color: Colors.white24),
              _buildStatColumn('Win Rate', '$winRate%', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildGameStatCard(GameStatData game) {
    final wins = playerStats.getWins(game.id);
    final losses = playerStats.getLosses(game.id);
    final draws = playerStats.getDraws(game.id);
    final gamesPlayed = playerStats.getGamesPlayed(game.id);
    final winRate = playerStats.getWinRate(game.id);
    final bestStreak = playerStats.getBestStreak(game.id);
    final vsComputerWins = playerStats.getVsComputerWins(game.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: game.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcons.svg(game.icon, size: 24, color: game.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '$gamesPlayed games played',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Win rate badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getWinRateColor(winRate).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${winRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getWinRateColor(winRate),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('W', wins, Colors.green),
              _buildMiniStat('L', losses, Colors.red),
              _buildMiniStat('D', draws, Colors.grey),
              _buildMiniStat('🔥', bestStreak, Colors.orange),
              if (vsComputerWins > 0) _buildMiniStat('🤖', vsComputerWins, game.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getWinRateColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 50) return Colors.orange;
    if (rate >= 30) return Colors.amber;
    return Colors.red;
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset All Stats?', textAlign: TextAlign.center),
        content: const Text(
          'This will permanently delete all your game statistics. This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await playerStats.resetAllStats();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All stats have been reset')),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHighScoreCard(HighScoreGameData game) {
    final highScore = HighScoreService.getHighScore(game.id);
    final hasScore = highScore > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasScore ? Border.all(color: game.color.withAlpha(100), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: hasScore ? game.color.withAlpha(20) : Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Game Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: game.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcons.svg(game.icon, size: 28, color: game.color),
          ),
          const SizedBox(width: 15),

          // Game Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  hasScore ? 'Personal Best' : 'No score yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasScore ? game.color : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // High Score Display
          if (hasScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [game.color, game.color.withAlpha(180)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: game.color.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '👑 ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    _formatScore(highScore),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-- --',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}

class GameStatData {
  final String name;
  final String icon;
  final String id;
  final Color color;

  GameStatData(this.name, this.icon, this.id, this.color);
}

class HighScoreGameData {
  final String name;
  final String icon;
  final String id;
  final Color color;

  HighScoreGameData(this.name, this.icon, this.id, this.color);
}
