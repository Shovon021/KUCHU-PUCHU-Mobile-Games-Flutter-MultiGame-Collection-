import 'package:shared_preferences/shared_preferences.dart';
import 'player_stats_service.dart';

/// Achievement definitions
enum Achievement {
  firstWin,
  tenWins,
  fiftyWins,
  hundredWins,
  firstStreak,
  fiveStreak,
  tenStreak,
  beatEasyAI,
  beatMediumAI,
  beatHardAI,
  allGamesPlayed,
  perfectGame,
  dedication;

  String get id => name;

  String get title {
    switch (this) {
      case Achievement.firstWin:
        return 'First Victory';
      case Achievement.tenWins:
        return 'Getting Good';
      case Achievement.fiftyWins:
        return 'Winning Streak';
      case Achievement.hundredWins:
        return 'Champion';
      case Achievement.firstStreak:
        return 'On Fire';
      case Achievement.fiveStreak:
        return 'Unstoppable';
      case Achievement.tenStreak:
        return 'Legendary';
      case Achievement.beatEasyAI:
        return 'Beginner Beater';
      case Achievement.beatMediumAI:
        return 'Challenge Accepted';
      case Achievement.beatHardAI:
        return 'AI Master';
      case Achievement.allGamesPlayed:
        return 'Explorer';
      case Achievement.perfectGame:
        return 'Flawless';
      case Achievement.dedication:
        return 'Dedicated';
    }
  }

  String get description {
    switch (this) {
      case Achievement.firstWin:
        return 'Win your first game';
      case Achievement.tenWins:
        return 'Win 10 games total';
      case Achievement.fiftyWins:
        return 'Win 50 games total';
      case Achievement.hundredWins:
        return 'Win 100 games total';
      case Achievement.firstStreak:
        return 'Win 3 games in a row';
      case Achievement.fiveStreak:
        return 'Win 5 games in a row';
      case Achievement.tenStreak:
        return 'Win 10 games in a row';
      case Achievement.beatEasyAI:
        return 'Beat the Easy computer';
      case Achievement.beatMediumAI:
        return 'Beat the Medium computer';
      case Achievement.beatHardAI:
        return 'Beat the Hard computer';
      case Achievement.allGamesPlayed:
        return 'Play all 15 games';
      case Achievement.perfectGame:
        return 'Win without any losses';
      case Achievement.dedication:
        return 'Play 100 games total';
    }
  }

  String get emoji {
    switch (this) {
      case Achievement.firstWin:
        return '🏆';
      case Achievement.tenWins:
        return '⭐';
      case Achievement.fiftyWins:
        return '🌟';
      case Achievement.hundredWins:
        return '👑';
      case Achievement.firstStreak:
        return '🔥';
      case Achievement.fiveStreak:
        return '💪';
      case Achievement.tenStreak:
        return '🚀';
      case Achievement.beatEasyAI:
        return '🤖';
      case Achievement.beatMediumAI:
        return '🧠';
      case Achievement.beatHardAI:
        return '💎';
      case Achievement.allGamesPlayed:
        return '🎮';
      case Achievement.perfectGame:
        return '✨';
      case Achievement.dedication:
        return '❤️';
    }
  }

  int get points {
    switch (this) {
      case Achievement.firstWin:
        return 10;
      case Achievement.tenWins:
        return 50;
      case Achievement.fiftyWins:
        return 100;
      case Achievement.hundredWins:
        return 200;
      case Achievement.firstStreak:
        return 25;
      case Achievement.fiveStreak:
        return 75;
      case Achievement.tenStreak:
        return 150;
      case Achievement.beatEasyAI:
        return 20;
      case Achievement.beatMediumAI:
        return 50;
      case Achievement.beatHardAI:
        return 100;
      case Achievement.allGamesPlayed:
        return 50;
      case Achievement.perfectGame:
        return 75;
      case Achievement.dedication:
        return 100;
    }
  }
}

/// Service to manage achievements
class AchievementsService {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  SharedPreferences? _prefs;
  final Set<Achievement> _unlockedAchievements = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUnlockedAchievements();
  }

  void _loadUnlockedAchievements() {
    for (var achievement in Achievement.values) {
      if (_prefs?.getBool('achievement_${achievement.id}') == true) {
        _unlockedAchievements.add(achievement);
      }
    }
  }

  bool isUnlocked(Achievement achievement) {
    return _unlockedAchievements.contains(achievement);
  }

  Set<Achievement> get unlockedAchievements => Set.from(_unlockedAchievements);

  int get totalPoints {
    return _unlockedAchievements.fold(0, (sum, a) => sum + a.points);
  }

  int get unlockedCount => _unlockedAchievements.length;
  int get totalCount => Achievement.values.length;

  Future<Achievement?> unlock(Achievement achievement) async {
    if (_unlockedAchievements.contains(achievement)) return null;
    
    _unlockedAchievements.add(achievement);
    await _prefs?.setBool('achievement_${achievement.id}', true);
    return achievement;
  }

  /// Check and unlock achievements based on current stats
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    List<Achievement> newlyUnlocked = [];
    
    final totalWins = playerStats.getTotalWins();
    final totalGames = playerStats.getTotalGamesPlayed();

    // Win count achievements
    if (totalWins >= 1) {
      final a = await unlock(Achievement.firstWin);
      if (a != null) newlyUnlocked.add(a);
    }
    if (totalWins >= 10) {
      final a = await unlock(Achievement.tenWins);
      if (a != null) newlyUnlocked.add(a);
    }
    if (totalWins >= 50) {
      final a = await unlock(Achievement.fiftyWins);
      if (a != null) newlyUnlocked.add(a);
    }
    if (totalWins >= 100) {
      final a = await unlock(Achievement.hundredWins);
      if (a != null) newlyUnlocked.add(a);
    }

    // Streak achievements - check best streak across all games
    int maxStreak = 0;
    for (var game in [
      PlayerStatsService.ticTacToe,
      PlayerStatsService.connectFour,
      PlayerStatsService.snakeLadder,
      PlayerStatsService.memoryMatch,
      PlayerStatsService.ludo,
    ]) {
      final streak = playerStats.getBestStreak(game);
      if (streak > maxStreak) maxStreak = streak;
    }

    if (maxStreak >= 3) {
      final a = await unlock(Achievement.firstStreak);
      if (a != null) newlyUnlocked.add(a);
    }
    if (maxStreak >= 5) {
      final a = await unlock(Achievement.fiveStreak);
      if (a != null) newlyUnlocked.add(a);
    }
    if (maxStreak >= 10) {
      final a = await unlock(Achievement.tenStreak);
      if (a != null) newlyUnlocked.add(a);
    }

    // Dedication achievement
    if (totalGames >= 100) {
      final a = await unlock(Achievement.dedication);
      if (a != null) newlyUnlocked.add(a);
    }

    return newlyUnlocked;
  }

  /// Unlock AI difficulty achievements
  Future<Achievement?> unlockAIDifficulty(String difficulty) async {
    switch (difficulty) {
      case 'easy':
        return await unlock(Achievement.beatEasyAI);
      case 'medium':
        return await unlock(Achievement.beatMediumAI);
      case 'hard':
        return await unlock(Achievement.beatHardAI);
      default:
        return null;
    }
  }

  Future<void> resetAllAchievements() async {
    for (var achievement in Achievement.values) {
      await _prefs?.remove('achievement_${achievement.id}');
    }
    _unlockedAchievements.clear();
  }
}

// Global instance
final achievements = AchievementsService();
