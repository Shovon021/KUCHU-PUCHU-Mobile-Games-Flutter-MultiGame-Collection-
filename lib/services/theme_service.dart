import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App color theme definition
class AppTheme {
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color cardBackground;
  final List<Color> gradient;

  const AppTheme({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.cardBackground,
    required this.gradient,
  });
}

/// Service for managing app themes
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static ThemeService? _instance;
  
  int _currentThemeIndex = 0;
  
  // Available themes (no dark mode, all light backgrounds)
  static const List<AppTheme> themes = [
    // 🍊 Orange (Default)
    AppTheme(
      name: 'Orange',
      emoji: '🍊',
      primary: Color(0xFFFF8C42),
      secondary: Color(0xFFFF6B35),
      background: Color(0xFFFFFBF5),
      cardBackground: Color(0xFFFFFFFF),
      gradient: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
    ),
    // 🌊 Ocean
    AppTheme(
      name: 'Ocean',
      emoji: '🌊',
      primary: Color(0xFF0077B6),
      secondary: Color(0xFF00B4D8),
      background: Color(0xFFF0F9FF),
      cardBackground: Color(0xFFFFFFFF),
      gradient: [Color(0xFF0077B6), Color(0xFF00B4D8)],
    ),
    // 🌿 Nature
    AppTheme(
      name: 'Nature',
      emoji: '🌿',
      primary: Color(0xFF2D6A4F),
      secondary: Color(0xFF40916C),
      background: Color(0xFFF0FFF4),
      cardBackground: Color(0xFFFFFFFF),
      gradient: [Color(0xFF2D6A4F), Color(0xFF40916C)],
    ),
    // 🍇 Purple
    AppTheme(
      name: 'Purple',
      emoji: '🍇',
      primary: Color(0xFF7B2CBF),
      secondary: Color(0xFF9D4EDD),
      background: Color(0xFFF5F0FF),
      cardBackground: Color(0xFFFFFFFF),
      gradient: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
    ),
    // 🌸 Rose
    AppTheme(
      name: 'Rose',
      emoji: '🌸',
      primary: Color(0xFFE91E63),
      secondary: Color(0xFFFF4081),
      background: Color(0xFFFFF0F5),
      cardBackground: Color(0xFFFFFFFF),
      gradient: [Color(0xFFE91E63), Color(0xFFFF4081)],
    ),
  ];
  
  ThemeService._();
  
  static ThemeService get instance {
    _instance ??= ThemeService._();
    return _instance!;
  }
  
  AppTheme get currentTheme => themes[_currentThemeIndex];
  int get currentIndex => _currentThemeIndex;
  
  /// Initialize theme from saved preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeIndex = prefs.getInt(_themeKey) ?? 0;
    if (_currentThemeIndex >= themes.length) _currentThemeIndex = 0;
    notifyListeners();
  }
  
  /// Set theme by index
  Future<void> setTheme(int index) async {
    if (index < 0 || index >= themes.length) return;
    _currentThemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, index);
    notifyListeners();
  }
  
  /// Get Flutter ThemeData based on current theme
  ThemeData getThemeData() {
    final theme = currentTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: theme.primary,
      scaffoldBackgroundColor: theme.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primary,
        brightness: Brightness.light,
        primary: theme.primary,
        secondary: theme.secondary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D3436)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D3436),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
