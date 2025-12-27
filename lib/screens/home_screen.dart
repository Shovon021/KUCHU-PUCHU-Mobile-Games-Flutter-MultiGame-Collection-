import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../games/tic_tac_toe_screen.dart';
import '../games/ludo_screen.dart';
import '../games/snake_ladder_screen.dart';
import '../games/memory_match_screen.dart';
import '../games/connect_four_screen.dart';
import '../games/dots_boxes_screen.dart';
import '../games/simon_says_screen.dart';
import '../games/reaction_game_screen.dart';
import '../games/number_guess_screen.dart';
import '../games/bounce_tales_screen.dart';
import '../games/diamond_rush_screen.dart';
import '../games/arkanoid_screen.dart';
import '../games/tetris_screen.dart';
import '../games/candy_crush_screen.dart';
import '../games/space_shooter_screen.dart';

import '../services/theme_service.dart';
import '../services/music_service.dart';
import '../widgets/app_icons.dart';
import 'settings_screen.dart';

// Custom animated page route with slide + fade
class _SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  _SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(curve),
                child: child,
              ),
            );
          },
        );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Theme colors
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeService.instance.currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Choose Theme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: List.generate(ThemeService.themes.length, (index) {
                final theme = ThemeService.themes[index];
                final isSelected = ThemeService.instance.currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    ThemeService.instance.setTheme(index);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80, height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theme.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all(color: textDark, width: 3) : null,
                      boxShadow: [BoxShadow(color: theme.primary.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(theme.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 5),
                        Text(theme.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (isSelected) AppIcons.svg('check-circle', size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.instance.currentTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Modern Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theme.gradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withAlpha(80),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AppIcons.svg('gamepad', size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Game Box',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '15 Fun Offline Games',
                        style: TextStyle(
                          fontSize: 14,
                          color: textLight.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Settings button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) => setState(() {})); // Refresh on return
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/settings.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(theme.primary, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Games Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _GameCard(
                      title: 'Tic Tac Toe',
                      svgIcon: 'tag',
                      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      players: '2 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const TicTacToeScreen())),
                    ),
                    _GameCard(
                      title: 'Ludo',
                      svgIcon: 'casino',
                      gradient: const [Color(0xFFFF8C42), Color(0xFFFF6B35)],
                      players: '2-4 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const LudoScreen())),
                    ),
                    _GameCard(
                      title: 'Snakes & Ladders',
                      svgIcon: 'trending',
                      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                      players: '2-4 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const SnakeLadderScreen())),
                    ),
                    _GameCard(
                      title: 'Memory Match',
                      svgIcon: 'brain',
                      gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                      players: '2-4 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const MemoryMatchScreen())),
                    ),
                    _GameCard(
                      title: 'Connect Four',
                      svgIcon: 'connect-four',
                      gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      players: '2 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const ConnectFourScreen())),
                    ),
                    _GameCard(
                      title: 'Dots & Boxes',
                      svgIcon: 'grid',
                      gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      players: '2 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const DotsBoxesScreen())),
                    ),
                    _GameCard(
                      title: 'Simon Says',
                      svgIcon: 'brain',
                      gradient: const [Color(0xFFE53935), Color(0xFFFDD835)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const SimonSaysScreen())),
                    ),
                    _GameCard(
                      title: 'Reaction Game',
                      svgIcon: 'flash',
                      gradient: const [Color(0xFF43A047), Color(0xFF66BB6A)],
                      players: '2 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const ReactionGameScreen())),
                    ),
                    _GameCard(
                      title: 'Number Guess',
                      svgIcon: 'target',
                      gradient: const [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                      players: '2 Players',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const NumberGuessScreen())),
                    ),
                    _GameCard(
                      title: 'Bounce Tales',
                      svgIcon: 'circle',
                      gradient: const [Color(0xFFE53935), Color(0xFFFF5722)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const BounceTalesScreen())),
                    ),
                    _GameCard(
                      title: 'Diamond Rush',
                      svgIcon: 'diamond',
                      gradient: const [Color(0xFF00D9FF), Color(0xFF00A8CC)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const DiamondRushScreen())),
                    ),
                    _GameCard(
                      title: 'Arkanoid',
                      svgIcon: 'brick',
                      gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const ArkanoidScreen())),
                    ),
                    _GameCard(
                      title: 'Tetris',
                      svgIcon: 'tetris',
                      gradient: const [Color(0xFF00CED1), Color(0xFF20B2AA)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const TetrisScreen())),
                    ),
                    _GameCard(
                      title: 'Candy Crush',
                      svgIcon: 'candy',
                      gradient: const [Color(0xFFFF6B9D), Color(0xFFC44569)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const CandyCrushScreen())),
                    ),
                    _GameCard(
                      title: 'Space Shooter',
                      svgIcon: 'rocket',
                      gradient: const [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      players: '1 Player',
                      onTap: () => Navigator.push(context, _SlideUpRoute(page: const SpaceShooterScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final String title;
  final String svgIcon;
  final List<Color> gradient;
  final String players;
  final VoidCallback onTap;
  final bool isLocked;

  const _GameCard({
    required this.title,
    required this.svgIcon,
    required this.gradient,
    required this.players,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLocked) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (!widget.isLocked) {
      widget.onTap();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((15 * _scaleAnimation.value).round()),
                    blurRadius: 20 * _scaleAnimation.value,
                    offset: Offset(0, 8 * _scaleAnimation.value),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background accent
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.gradient),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: widget.gradient),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: widget.isLocked ? [] : [
                              BoxShadow(
                                color: widget.gradient[0].withAlpha(100),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/${widget.svgIcon}.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isLocked ? Colors.grey : const Color(0xFF2D3436),
                          ),
                        ),
                        if (widget.players.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.players,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Lock overlay
                  if (widget.isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(150),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/lock.svg',
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
