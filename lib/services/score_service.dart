import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing high scores across all games
class ScoreService {
  static const String _prefix = 'high_score_';
  static SharedPreferences? _prefs;
  
  /// Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get high score for a game
  static int getHighScore(String gameId) {
    return _prefs?.getInt('$_prefix$gameId') ?? 0;
  }
  
  /// Save high score if it's higher than existing
  static Future<bool> saveHighScore(String gameId, int score) async {
    int currentHigh = getHighScore(gameId);
    if (score > currentHigh) {
      await _prefs?.setInt('$_prefix$gameId', score);
      return true; // New high score!
    }
    return false;
  }
  
  /// Reset high score for a game
  static Future<void> resetHighScore(String gameId) async {
    await _prefs?.remove('$_prefix$gameId');
  }
  
  /// Get all saved high scores
  static Map<String, int> getAllHighScores() {
    Map<String, int> scores = {};
    if (_prefs != null) {
      for (String key in _prefs!.getKeys()) {
        if (key.startsWith(_prefix)) {
          String gameId = key.substring(_prefix.length);
          scores[gameId] = _prefs!.getInt(key) ?? 0;
        }
      }
    }
    return scores;
  }
}

/// Game IDs for consistent score tracking
class GameIds {
  static const String ticTacToe = 'tic_tac_toe';
  static const String ludo = 'ludo';
  static const String snakeLadder = 'snake_ladder';
  static const String memoryMatch = 'memory_match';
  static const String connectFour = 'connect_four';
  static const String dotsBoxes = 'dots_boxes';
  static const String simonSays = 'simon_says';
  static const String reactionGame = 'reaction_game';
  static const String numberGuess = 'number_guess';
  static const String bounceTales = 'bounce_tales';
  static const String diamondRush = 'diamond_rush';
}
