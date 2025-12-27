import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service for managing background music
class MusicService extends ChangeNotifier {
  static const String _musicKey = 'music_enabled';
  static const String _volumeKey = 'music_volume';
  static MusicService? _instance;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = false;
  bool _isPlaying = false;
  double _volume = 0.5; // Default 50%
  
  MusicService._();
  
  static MusicService get instance {
    _instance ??= MusicService._();
    return _instance!;
  }
  
  bool get isEnabled => _isEnabled;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  
  /// Initialize music service from saved preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_musicKey) ?? false;
    _volume = prefs.getDouble(_volumeKey) ?? 0.5;
    
    // Set up audio player for looping
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(_volume);
    
    if (_isEnabled) {
      await play();
    }
    
    notifyListeners();
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
    
    notifyListeners();
  }
  
  /// Toggle music on/off
  Future<void> toggle() async {
    _isEnabled = !_isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, _isEnabled);
    
    if (_isEnabled) {
      await play();
    } else {
      await stop();
    }
    
    notifyListeners();
  }
  
  /// Play background music from asset
  Future<void> play() async {
    _isPlaying = false;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('audio/bgsong.mpeg'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Music error: $e');
      _isPlaying = false;
    }
  }
  
  /// Stop background music
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }
  
  /// Pause music (for when app goes to background)
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }
  
  /// Resume music
  Future<void> resume() async {
    if (_isEnabled) {
      await _audioPlayer.resume();
      _isPlaying = true;
    }
  }
  
  /// Dispose of audio player
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
