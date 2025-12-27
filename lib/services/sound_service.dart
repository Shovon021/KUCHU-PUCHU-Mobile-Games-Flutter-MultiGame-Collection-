import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for playing sound effects across all games
class SoundService {
  // Multiple audio players for overlapping sounds
  static final AudioPlayer _sfxPlayer1 = AudioPlayer();
  static final AudioPlayer _sfxPlayer2 = AudioPlayer();
  static final AudioPlayer _sfxPlayer3 = AudioPlayer();
  static int _currentPlayer = 0;
  
  static bool _soundEnabled = true;
  static double _volume = 1.0;
  static const String _soundKey = 'sound_effects_enabled';
  static const String _volumeKey = 'sound_effects_volume';
  
  /// Check if sound effects are enabled
  static bool get isSoundEnabled => _soundEnabled;
  static double get volume => _volume;
  
  /// Get next available player for overlapping sounds
  static AudioPlayer get _nextPlayer {
    _currentPlayer = (_currentPlayer + 1) % 3;
    switch (_currentPlayer) {
      case 0: return _sfxPlayer1;
      case 1: return _sfxPlayer2;
      default: return _sfxPlayer3;
    }
  }
  
  /// Initialize sound service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _volume = prefs.getDouble(_volumeKey) ?? 1.0;
  }
  
  /// Toggle sound effects on/off
  static Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
  }
  
  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
  }
  
  /// Play sound with pitch variation
  static Future<void> _play(String asset, {double rate = 1.0, double vol = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      final player = _nextPlayer;
      await player.setPlaybackRate(rate);
      await player.setVolume(_volume * vol);
      await player.play(AssetSource(asset));
    } catch (e) {
      // Silent fail
    }
  }
  
  // ==================== BASIC SOUNDS ====================
  
  /// Play a tap/click sound
  static Future<void> playTap() async {
    HapticFeedback.lightImpact();
    await _play('audio/tap.mp3');
  }
  
  /// Play a success/win sound
  static Future<void> playSuccess() async {
    HapticFeedback.mediumImpact();
    await _play('audio/win.mp3');
  }
  
  /// Play a failure/lose sound
  static Future<void> playFail() async {
    HapticFeedback.heavyImpact();
    await _play('audio/fail.mp3');
  }
  
  // ==================== GAME SOUNDS ====================
  
  /// Play a move/action sound (slightly lower pitch tap)
  static Future<void> playMove() async {
    HapticFeedback.selectionClick();
    await _play('audio/tap.mp3', rate: 0.9, vol: 0.7);
  }
  
  /// Play a coin/collect sound (high pitch tap)
  static Future<void> playCoin() async {
    HapticFeedback.lightImpact();
    await _play('audio/tap.mp3', rate: 1.5, vol: 0.8);
  }
  
  /// Play a jump sound (mid-high pitch tap)
  static Future<void> playJump() async {
    HapticFeedback.lightImpact();
    await _play('audio/tap.mp3', rate: 1.3, vol: 0.9);
  }
  
  /// Play a bounce sound (quick, high pitch)
  static Future<void> playBounce() async {
    await _play('audio/tap.mp3', rate: 1.6, vol: 0.6);
  }
  
  /// Play a match sound (satisfying mid-tone)
  static Future<void> playMatch() async {
    HapticFeedback.mediumImpact();
    await _play('audio/tap.mp3', rate: 1.2, vol: 0.9);
  }
  
  /// Play block/brick hit sound (low thud)
  static Future<void> playBlock() async {
    await _play('audio/tap.mp3', rate: 0.7, vol: 0.8);
  }
  
  /// Play power-up collect sound (rising tone - win at high pitch)
  static Future<void> playPowerUp() async {
    HapticFeedback.mediumImpact();
    await _play('audio/win.mp3', rate: 1.4, vol: 0.7);
  }
  
  /// Play combo sound (win at slightly higher pitch)
  static Future<void> playCombo() async {
    HapticFeedback.heavyImpact();
    await _play('audio/win.mp3', rate: 1.2, vol: 0.9);
  }
  
  /// Play explosion/death sound (low fail)
  static Future<void> playExplosion() async {
    HapticFeedback.heavyImpact();
    await _play('audio/fail.mp3', rate: 0.8, vol: 1.0);
  }
  
  /// Play countdown tick (quick tap)
  static Future<void> playTick() async {
    await _play('audio/tap.mp3', rate: 1.4, vol: 0.5);
  }
  
  /// Play countdown final tick (emphasized)
  static Future<void> playTickFinal() async {
    HapticFeedback.mediumImpact();
    await _play('audio/tap.mp3', rate: 1.0, vol: 1.0);
  }
  
  // ==================== SPECIAL SOUNDS ====================
  
  /// Play a death/game over sound (slower fail)
  static Future<void> playGameOver() async {
    HapticFeedback.heavyImpact();
    await _play('audio/fail.mp3', rate: 0.9);
  }
  
  /// Play a level complete sound (triumphant win)
  static Future<void> playLevelComplete() async {
    HapticFeedback.heavyImpact();
    await _play('audio/win.mp3', rate: 1.1);
  }
  
  /// Play a new high score celebration (excited win)
  static Future<void> playHighScore() async {
    HapticFeedback.heavyImpact();
    await _play('audio/win.mp3', rate: 1.15);
  }
  
  /// Play achievement unlock sound
  static Future<void> playAchievement() async {
    HapticFeedback.heavyImpact();
    await _play('audio/win.mp3', rate: 1.3, vol: 1.0);
  }
  
  /// Play button press (very light tap)
  static Future<void> playButton() async {
    HapticFeedback.selectionClick();
    await _play('audio/tap.mp3', rate: 1.1, vol: 0.5);
  }
  
  /// Play card flip sound
  static Future<void> playFlip() async {
    await _play('audio/tap.mp3', rate: 1.4, vol: 0.6);
  }
  
  /// Play dice roll sound (series of quick taps simulated by one)
  static Future<void> playDice() async {
    HapticFeedback.lightImpact();
    await _play('audio/tap.mp3', rate: 0.8, vol: 0.7);
  }
  
  /// Dispose all audio players
  static void dispose() {
    _sfxPlayer1.dispose();
    _sfxPlayer2.dispose();
    _sfxPlayer3.dispose();
  }
}
