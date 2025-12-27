import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage high scores for all games using SharedPreferences
class HighScoreService {
  static SharedPreferences? _prefs;
  
  // Game identifiers
  static const String spaceShooter = 'space_shooter';
  static const String tetris = 'tetris';
  static const String arkanoid = 'arkanoid';
  static const String candyCrush = 'candy_crush';
  static const String bounceTales = 'bounce_tales';
  static const String diamondRush = 'diamond_rush';
  static const String memoryMatch = 'memory_match';
  
  /// Initialize SharedPreferences (call once at app start)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get high score for a game
  static int getHighScore(String gameId) {
    return _prefs?.getInt('highscore_$gameId') ?? 0;
  }
  
  /// Set high score for a game (only if higher than current)
  /// Returns true if new high score was set
  static Future<bool> setHighScore(String gameId, int score) async {
    final currentHigh = getHighScore(gameId);
    if (score > currentHigh) {
      await _prefs?.setInt('highscore_$gameId', score);
      return true; // New high score!
    }
    return false;
  }
  
  /// Force set a high score (for debugging/reset)
  static Future<void> forceSetHighScore(String gameId, int score) async {
    await _prefs?.setInt('highscore_$gameId', score);
  }
  
  /// Reset all high scores
  static Future<void> resetAllScores() async {
    final games = [spaceShooter, tetris, arkanoid, candyCrush, bounceTales, diamondRush, memoryMatch];
    for (var game in games) {
      await _prefs?.remove('highscore_$game');
    }
  }
  
  /// Get all high scores as a map
  static Map<String, int> getAllHighScores() {
    return {
      'Space Shooter': getHighScore(spaceShooter),
      'Tetris': getHighScore(tetris),
      'Arkanoid': getHighScore(arkanoid),
      'Candy Crush': getHighScore(candyCrush),
      'Bounce Tales': getHighScore(bounceTales),
      'Diamond Rush': getHighScore(diamondRush),
      'Memory Match': getHighScore(memoryMatch),
    };
  }
}
