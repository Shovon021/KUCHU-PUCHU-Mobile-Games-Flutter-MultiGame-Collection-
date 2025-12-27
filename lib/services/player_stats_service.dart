import 'package:shared_preferences/shared_preferences.dart';

/// Service to track player statistics across all games
class PlayerStatsService {
  static final PlayerStatsService _instance = PlayerStatsService._internal();
  factory PlayerStatsService() => _instance;
  PlayerStatsService._internal();

  SharedPreferences? _prefs;

  // Game identifiers
  static const String ticTacToe = 'tic_tac_toe';
  static const String connectFour = 'connect_four';
  static const String snakeLadder = 'snake_ladder';
  static const String memoryMatch = 'memory_match';
  static const String simonSays = 'simon_says';
  static const String ludo = 'ludo';
  static const String dotsBoxes = 'dots_boxes';
  static const String reactionGame = 'reaction_game';
  static const String numberGuess = 'number_guess';
  static const String bounceTales = 'bounce_tales';
  static const String diamondRush = 'diamond_rush';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys for stats
  String _winsKey(String game) => '${game}_wins';
  String _lossesKey(String game) => '${game}_losses';
  String _drawsKey(String game) => '${game}_draws';
  String _gamesPlayedKey(String game) => '${game}_games_played';
  String _winStreakKey(String game) => '${game}_win_streak';
  String _bestStreakKey(String game) => '${game}_best_streak';
  String _vsComputerWinsKey(String game) => '${game}_vs_computer_wins';

  // Get stats
  int getWins(String game) => _prefs?.getInt(_winsKey(game)) ?? 0;
  int getLosses(String game) => _prefs?.getInt(_lossesKey(game)) ?? 0;
  int getDraws(String game) => _prefs?.getInt(_drawsKey(game)) ?? 0;
  int getGamesPlayed(String game) => _prefs?.getInt(_gamesPlayedKey(game)) ?? 0;
  int getWinStreak(String game) => _prefs?.getInt(_winStreakKey(game)) ?? 0;
  int getBestStreak(String game) => _prefs?.getInt(_bestStreakKey(game)) ?? 0;
  int getVsComputerWins(String game) => _prefs?.getInt(_vsComputerWinsKey(game)) ?? 0;

  // Calculate win rate
  double getWinRate(String game) {
    final total = getGamesPlayed(game);
    if (total == 0) return 0.0;
    return (getWins(game) / total) * 100;
  }

  // Record a win
  Future<void> recordWin(String game, {bool vsComputer = false}) async {
    final wins = getWins(game) + 1;
    final gamesPlayed = getGamesPlayed(game) + 1;
    final streak = getWinStreak(game) + 1;
    final bestStreak = getBestStreak(game);

    await _prefs?.setInt(_winsKey(game), wins);
    await _prefs?.setInt(_gamesPlayedKey(game), gamesPlayed);
    await _prefs?.setInt(_winStreakKey(game), streak);
    
    if (streak > bestStreak) {
      await _prefs?.setInt(_bestStreakKey(game), streak);
    }

    if (vsComputer) {
      final vsWins = getVsComputerWins(game) + 1;
      await _prefs?.setInt(_vsComputerWinsKey(game), vsWins);
    }
  }

  // Record a loss
  Future<void> recordLoss(String game) async {
    final losses = getLosses(game) + 1;
    final gamesPlayed = getGamesPlayed(game) + 1;

    await _prefs?.setInt(_lossesKey(game), losses);
    await _prefs?.setInt(_gamesPlayedKey(game), gamesPlayed);
    await _prefs?.setInt(_winStreakKey(game), 0); // Reset streak
  }

  // Record a draw
  Future<void> recordDraw(String game) async {
    final draws = getDraws(game) + 1;
    final gamesPlayed = getGamesPlayed(game) + 1;

    await _prefs?.setInt(_drawsKey(game), draws);
    await _prefs?.setInt(_gamesPlayedKey(game), gamesPlayed);
  }

  // Get total stats across all games
  int getTotalWins() {
    return getWins(ticTacToe) + getWins(connectFour) + getWins(snakeLadder) +
           getWins(memoryMatch) + getWins(ludo) + getWins(dotsBoxes) +
           getWins(reactionGame) + getWins(numberGuess);
  }

  int getTotalGamesPlayed() {
    return getGamesPlayed(ticTacToe) + getGamesPlayed(connectFour) + 
           getGamesPlayed(snakeLadder) + getGamesPlayed(memoryMatch) + 
           getGamesPlayed(ludo) + getGamesPlayed(dotsBoxes) +
           getGamesPlayed(reactionGame) + getGamesPlayed(numberGuess);
  }

  // Reset stats for a game
  Future<void> resetGameStats(String game) async {
    await _prefs?.remove(_winsKey(game));
    await _prefs?.remove(_lossesKey(game));
    await _prefs?.remove(_drawsKey(game));
    await _prefs?.remove(_gamesPlayedKey(game));
    await _prefs?.remove(_winStreakKey(game));
    await _prefs?.remove(_bestStreakKey(game));
    await _prefs?.remove(_vsComputerWinsKey(game));
  }

  // Reset all stats
  Future<void> resetAllStats() async {
    final games = [ticTacToe, connectFour, snakeLadder, memoryMatch, 
                   simonSays, ludo, dotsBoxes, reactionGame, numberGuess,
                   bounceTales, diamondRush];
    for (final game in games) {
      await resetGameStats(game);
    }
  }
}

// Global instance for easy access
final playerStats = PlayerStatsService();
