import 'package:shared_preferences/shared_preferences.dart';

/// AI difficulty levels
enum AIDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case AIDifficulty.easy:
        return 'Easy';
      case AIDifficulty.medium:
        return 'Medium';
      case AIDifficulty.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case AIDifficulty.easy:
        return '😊';
      case AIDifficulty.medium:
        return '🤔';
      case AIDifficulty.hard:
        return '🧠';
    }
  }

  String get description {
    switch (this) {
      case AIDifficulty.easy:
        return 'For beginners';
      case AIDifficulty.medium:
        return 'Balanced challenge';
      case AIDifficulty.hard:
        return 'Expert level';
    }
  }

  /// Depth for minimax algorithm (higher = smarter)
  int get searchDepth {
    switch (this) {
      case AIDifficulty.easy:
        return 1;
      case AIDifficulty.medium:
        return 3;
      case AIDifficulty.hard:
        return 6;
    }
  }

  /// Chance of making a random (non-optimal) move
  double get mistakeChance {
    switch (this) {
      case AIDifficulty.easy:
        return 0.4; // 40% chance of random move
      case AIDifficulty.medium:
        return 0.15; // 15% chance of random move
      case AIDifficulty.hard:
        return 0.0; // Always optimal
    }
  }
}

/// Service to manage AI difficulty settings
class AIDifficultyService {
  static final AIDifficultyService _instance = AIDifficultyService._internal();
  factory AIDifficultyService() => _instance;
  AIDifficultyService._internal();

  SharedPreferences? _prefs;
  static const String _difficultyKey = 'ai_difficulty';

  AIDifficulty _difficulty = AIDifficulty.medium;
  AIDifficulty get difficulty => _difficulty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedDifficulty = _prefs?.getString(_difficultyKey);
    if (savedDifficulty != null) {
      _difficulty = AIDifficulty.values.firstWhere(
        (d) => d.name == savedDifficulty,
        orElse: () => AIDifficulty.medium,
      );
    }
  }

  Future<void> setDifficulty(AIDifficulty difficulty) async {
    _difficulty = difficulty;
    await _prefs?.setString(_difficultyKey, difficulty.name);
  }
}

// Global instance
final aiDifficulty = AIDifficultyService();
