import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/app_icons.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  static const Color cream = Color(0xFFFFFBF5);
  static const Color textDark = Color(0xFF2D3436);

  static const List<Color> playerColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];
  static const List<String> playerNames = ['Red', 'Blue', 'Green', 'Yellow'];

  // Card emojis for matching
  static const List<String> cardEmojis = [
    '🍎', '🍊', '🍋', '🍇', '🍓', '🍒', '🥝', '🍑',
    '🌸', '🌺', '🌻', '🌹', '🦋', '🐝', '🐞', '🦄',
  ];

  int? numPlayers;
  List<int> playerScores = [0, 0, 0, 0];
  int currentPlayer = 0;
  List<String> cards = [];
  List<bool> revealed = [];
  List<bool> matched = [];
  int? firstCardIndex;
  int? secondCardIndex;
  bool isProcessing = false;
  int? winner;

  void _startGame(int players) {
    SoundService.playTap();
    setState(() {
      numPlayers = players;
      playerScores = [0, 0, 0, 0];
      currentPlayer = 0;
      winner = null;
      isProcessing = false;
      firstCardIndex = null;
      secondCardIndex = null;

      // Create card pairs (16 cards = 8 pairs for 4x4 grid)
      List<String> selectedEmojis = List.from(cardEmojis.sublist(0, 8));
      cards = [...selectedEmojis, ...selectedEmojis]; // Duplicate for pairs
      cards.shuffle(Random());
      
      revealed = List.filled(16, false);
      matched = List.filled(16, false);
    });
  }

  void _onCardTap(int index) {
    if (isProcessing) return;
    if (revealed[index] || matched[index]) return;
    if (firstCardIndex == index) return;

    SoundService.playTap();
    setState(() => revealed[index] = true);

    if (firstCardIndex == null) {
      // First card selected
      setState(() => firstCardIndex = index);
    } else {
      // Second card selected
      setState(() {
        secondCardIndex = index;
        isProcessing = true;
      });

      // Check for match after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    if (firstCardIndex == null || secondCardIndex == null) return;

    bool isMatch = cards[firstCardIndex!] == cards[secondCardIndex!];

    setState(() {
      if (isMatch) {
        // Match found!
        SoundService.playSuccess();
        matched[firstCardIndex!] = true;
        matched[secondCardIndex!] = true;
        playerScores[currentPlayer]++;
        
        // Check win
        if (matched.every((m) => m)) {
          _determineWinner();
        }
      } else {
        // No match - hide cards
        SoundService.playFail();
        revealed[firstCardIndex!] = false;
        revealed[secondCardIndex!] = false;
        // Next player's turn
        currentPlayer = (currentPlayer + 1) % numPlayers!;
      }

      firstCardIndex = null;
      secondCardIndex = null;
      isProcessing = false;
    });
  }

  void _determineWinner() {
    int maxScore = playerScores.sublist(0, numPlayers!).reduce(max);
    List<int> winners = [];
    for (int i = 0; i < numPlayers!; i++) {
      if (playerScores[i] == maxScore) winners.add(i);
    }
    
    setState(() => winner = winners.length == 1 ? winners[0] : -1); // -1 = tie
    SoundService.playLevelComplete();
    _showWinDialog(winners);
  }

  void _showWinDialog(List<int> winners) {
    String title;
    if (winners.length == 1) {
      title = '${playerNames[winners[0]]} Wins! 🎉';
    } else {
      title = "It's a Tie! 🤝";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            AppIcons.trophy(size: 50, color: Colors.amber),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(
              color: winners.length == 1 ? playerColors[winners[0]] : textDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 10),
            Text(
              List.generate(numPlayers!, (i) => '${playerNames[i]}: ${playerScores[i]}').join(' | '),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startGame(numPlayers!);
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => numPlayers = null);
            },
            child: const Text('Change Players'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (numPlayers == null) return _buildPlayerSelection();
    return _buildGameScreen();
  }

  Widget _buildPlayerSelection() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: AppIcons.back(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memory Match', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            const Text('Select Players', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 10),
            const Text('Find matching pairs to score!', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: [
                _playerButton(2, '2 Players'),
                _playerButton(3, '3 Players'),
                _playerButton(4, '4 Players'),
              ],
            ),
            const SizedBox(height: 25),
            TextButton.icon(
              onPressed: () => showHowToPlay(context, GameRules.memoryMatch),
              icon: AppIcons.help(),
              label: const Text('How to Play?', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerButton(int count, String title) {
    return GestureDetector(
      onTap: () => _startGame(count),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            AppIcons.people(size: 35, color: playerColors[count - 2]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: AppIcons.back(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memory Match', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AppIcons.refresh(),
            onPressed: () => _startGame(numPlayers!),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scores bar
          _buildScoresBar(),
          
          // Current player indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: playerColors[currentPlayer],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${playerNames[currentPlayer]}'s Turn",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          // Card grid
          Expanded(child: _buildCardGrid()),
        ],
      ),
    );
  }

  Widget _buildScoresBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(numPlayers!, (i) {
          bool isActive = currentPlayer == i;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? playerColors[i] : playerColors[i].withAlpha(100),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(playerNames[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${playerScores[i]}', style: TextStyle(color: playerColors[i], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCardGrid() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(15),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 16,
            itemBuilder: (context, index) => _buildCard(index),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    bool isRevealed = revealed[index];
    bool isMatched = matched[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isMatched
              ? Colors.green.shade100
              : (isRevealed ? Colors.white : const Color(0xFF667EEA)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isRevealed ? Colors.black.withAlpha(20) : const Color(0xFF667EEA).withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isMatched ? Border.all(color: Colors.green, width: 2) : null,
        ),
        child: Center(
          child: isRevealed || isMatched
              ? Text(cards[index], style: const TextStyle(fontSize: 32))
              : const Text('?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
