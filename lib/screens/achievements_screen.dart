import 'package:flutter/material.dart';
import '../services/achievements_service.dart';
import '../widgets/app_icons.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  @override
  void initState() {
    super.initState();
    _checkNewAchievements();
  }

  Future<void> _checkNewAchievements() async {
    final newAchievements = await achievements.checkAndUnlockAchievements();
    if (newAchievements.isNotEmpty && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.unlockedCount;
    final totalCount = achievements.totalCount;
    final totalPoints = achievements.totalPoints;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

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
          'Achievements',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            _buildProgressCard(unlockedCount, totalCount, totalPoints, progress),
            const SizedBox(height: 25),

            // Section Title
            Row(
              children: [
                AppIcons.svg('star', size: 24, color: textDark),
                const SizedBox(width: 10),
                const Text(
                  'All Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Achievement Cards
            ...Achievement.values.map((achievement) => _buildAchievementCard(achievement)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int unlocked, int total, int points, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(80),
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
              AppIcons.svg('star', size: 36, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Achievement Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: MediaQuery.of(context).size.width * 0.7 * progress,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressStat('Unlocked', '$unlocked/$total', Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildProgressStat('Points', '$points', Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildProgressStat('Completion', '${(progress * 100).toStringAsFixed(0)}%', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievements.isUnlocked(achievement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? const Color(0xFFFFD700).withAlpha(30)
                : Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji/Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFFFD700).withAlpha(30)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: 28,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? textDark : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnlocked ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Points Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFFFD700).withAlpha(30)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${achievement.points}',
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFFFFA000) : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 14,
                  color: isUnlocked ? const Color(0xFFFFD700) : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
