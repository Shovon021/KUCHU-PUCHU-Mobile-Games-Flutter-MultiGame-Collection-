import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/theme_service.dart';
import '../services/music_service.dart';
import '../services/sound_service.dart';
import '../services/ai_difficulty_service.dart';
import '../widgets/app_icons.dart';
import '../services/score_service.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.instance.currentTheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.back(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Icon Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: theme.primary.withAlpha(100), blurRadius: 20),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icons/settings.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Sound Section
            _buildSectionTitleSvg('Sound', 'volume'),
            const SizedBox(height: 15),
            _buildSettingCardSvg(
              iconName: 'music',
              title: 'Background Music',
              subtitle: 'Soft looping music while playing',
              value: MusicService.instance.isEnabled,
              onChanged: (val) async {
                await MusicService.instance.toggle();
                setState(() {});
              },
            ),
            // Volume Slider (only show when music is enabled)
            if (MusicService.instance.isEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 8),
                child: Row(
                  children: [
                    Icon(Icons.volume_down, color: theme.primary, size: 20),
                    Expanded(
                      child: Slider(
                        value: MusicService.instance.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: theme.primary,
                        inactiveColor: theme.primary.withAlpha(50),
                        onChanged: (val) async {
                          await MusicService.instance.setVolume(val);
                          setState(() {});
                        },
                      ),
                    ),
                    Icon(Icons.volume_up, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${(MusicService.instance.volume * 100).round()}%',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _buildSettingCardSvg(
              iconName: 'hand-tap',
              title: 'Sound Effects',
              subtitle: 'Tap, win, and fail sounds',
              value: SoundService.isSoundEnabled,
              onChanged: (val) async {
                await SoundService.toggleSound();
                setState(() {});
              },
            ),
            const SizedBox(height: 30),
            
            // Game Settings Section
            _buildSectionTitleSvg('Game', 'robot'),
            const SizedBox(height: 15),
            _buildAIDifficultySelector(),
            const SizedBox(height: 30),
            
            // Stats & Progress Section
            _buildSectionTitleSvg('Stats & Progress', 'trending'),
            const SizedBox(height: 15),
            _buildNavigationCard(
              iconName: 'trophy',
              title: 'Your Statistics',
              subtitle: 'View wins, losses, and streaks',
              color: const Color(0xFF667EEA),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildNavigationCard(
              iconName: 'star',
              title: 'Achievements',
              subtitle: 'Unlock badges and rewards',
              color: const Color(0xFFFFD700),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ),
            ),
            const SizedBox(height: 30),
            
            // Appearance Section
            _buildSectionTitleSvg('Appearance', 'palette'),
            const SizedBox(height: 15),
            _buildThemeSelector(),
            const SizedBox(height: 30),
            
            // High Scores Section
            _buildSectionTitleSvg('High Scores', 'trophy'),
            const SizedBox(height: 15),
            _buildHighScoresCard(),
            const SizedBox(height: 30),
            
            // About Section
            _buildSectionTitleSvg('About', 'info'),
            const SizedBox(height: 15),
            _buildInfoCardSvg(
              iconName: 'gamepad',
              title: 'কুচু-পুচু Game Box',
              subtitle: 'Version 1.0.0',
            ),
            const SizedBox(height: 12),
            _buildInfoCardSvg(
              iconName: 'heart',
              title: 'Made with ❤️',
              subtitle: '11 classic games in one app',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitleSvg(String title, String iconName) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/icons/$iconName.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(Color(0xFF2D3436), BlendMode.srcIn),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCardSvg({
    required String iconName,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = ThemeService.instance.currentTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              'assets/icons/$iconName.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(theme.primary, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themes = ThemeService.themes; // Static list
    final currentTheme = ThemeService.instance.currentTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(themes.length, (index) {
              final theme = themes[index];
              final isSelected = theme == currentTheme;
              return GestureDetector(
                onTap: () {
                  ThemeService.instance.setTheme(index); // Pass index
                  setState(() {});
                },
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: theme.primary.withAlpha(150), blurRadius: 10)]
                        : [BoxShadow(color: theme.primary.withAlpha(50), blurRadius: 5)],
                  ),
                  child: Column(
                    children: [
                      if (isSelected)
                        AppIcons.svg('check-circle', size: 20, color: Colors.white)
                      else
                        const SizedBox(height: 20),
                      const SizedBox(height: 5),
                      Text(
                        theme.name,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardSvg({
    required String iconName,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/$iconName.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Color(0xFFFF8C42), BlendMode.srcIn),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighScoresCard() {
    final theme = ThemeService.instance.currentTheme;
    final simonScore = ScoreService.getHighScore('simon_says');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Simon Says Score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcons.svg('memory', size: 24, color: const Color(0xFFFFD700)),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text('Simon Says', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    AppIcons.trophy(size: 18, color: const Color(0xFFFFD700)),
                    const SizedBox(width: 5),
                    Text(
                      '$simonScore',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset High Scores?'),
                    content: const Text('This will clear all your high scores. Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ScoreService.resetHighScore('simon_says');
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: AppIcons.refresh(size: 18),
              label: const Text('Reset Scores'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDifficultySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.svg('robot', size: 24, color: const Color(0xFF667EEA)),
              const SizedBox(width: 12),
              const Text(
                'Computer Difficulty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Affects Tic Tac Toe & Connect Four',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 15),
          Row(
            children: AIDifficulty.values.map((difficulty) {
              final isSelected = aiDifficulty.difficulty == difficulty;
              final color = difficulty == AIDifficulty.easy
                  ? Colors.green
                  : difficulty == AIDifficulty.medium
                      ? Colors.orange
                      : Colors.red;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await aiDifficulty.setDifficulty(difficulty);
                    setState(() {});
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: difficulty != AIDifficulty.hard ? 10 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          difficulty.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          difficulty.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String iconName,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcons.svg(iconName, size: 24, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AppIcons.svg('arrow-forward', size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
