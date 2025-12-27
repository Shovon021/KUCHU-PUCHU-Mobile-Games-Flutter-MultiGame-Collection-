import 'package:flutter/material.dart';
import 'app_icons.dart';

/// Game instructions data
class GameInstructions {
  final String titleEn;
  final String titleBn;
  final List<String> rulesEn;
  final List<String> rulesBn;

  const GameInstructions({
    required this.titleEn,
    required this.titleBn,
    required this.rulesEn,
    required this.rulesBn,
  });
}

/// All game instructions
class GameRules {
  static const ticTacToe = GameInstructions(
    titleEn: 'Tic Tac Toe',
    titleBn: 'টিক ট্যাক টো',
    rulesEn: [
      '🎯 Get 3 in a row to win',
      '❌ Player 1 uses X',
      '⭕ Player 2 uses O',
      '🔄 Take turns placing marks',
      '↔️ Row, column, or diagonal wins',
    ],
    rulesBn: [
      '🎯 জিততে এক লাইনে ৩টি রাখুন',
      '❌ প্লেয়ার ১ X ব্যবহার করে',
      '⭕ প্লেয়ার ২ O ব্যবহার করে',
      '🔄 পালা করে চিহ্ন দিন',
      '↔️ সারি, কলাম বা কোণাকুণি জয়',
    ],
  );

  static const ludo = GameInstructions(
    titleEn: 'Ludo',
    titleBn: 'লুডু',
    rulesEn: [
      '🎲 Roll 6 to bring piece out',
      '🏃 Move pieces clockwise',
      '🎯 Reach home to score',
      '💥 Land on opponent to send back',
      '🏆 First to finish all wins',
    ],
    rulesBn: [
      '🎲 ঘুঁটি বের করতে ৬ পান',
      '🏃 ঘড়ির কাঁটার দিকে চলুন',
      '🎯 ঘরে পৌঁছান স্কোর করুন',
      '💥 প্রতিপক্ষকে ফেরত পাঠান',
      '🏆 প্রথম শেষ করলে জয়',
    ],
  );

  static const snakeLadder = GameInstructions(
    titleEn: 'Snakes & Ladders',
    titleBn: 'সাপ-লুডু',
    rulesEn: [
      '🎲 Roll dice to move forward',
      '🪜 Ladder takes you UP',
      '🐍 Snake brings you DOWN',
      '🎯 Reach 100 to win',
      '🔄 Take turns with opponent',
    ],
    rulesBn: [
      '🎲 ছক্কা গড়িয়ে এগিয়ে যান',
      '🪜 মই আপনাকে উপরে নেয়',
      '🐍 সাপ আপনাকে নিচে নামায়',
      '🎯 ১০০ তে পৌঁছে জিতুন',
      '🔄 পালা করে খেলুন',
    ],
  );

  static const memoryMatch = GameInstructions(
    titleEn: 'Memory Match',
    titleBn: 'মেমোরি ম্যাচ',
    rulesEn: [
      '🎴 Flip 2 cards each turn',
      '🧠 Remember card positions',
      '✅ Match pairs to score',
      '❌ Wrong match flips back',
      '🏆 Most pairs wins',
    ],
    rulesBn: [
      '🎴 প্রতি পালায় ২টি কার্ড খুলুন',
      '🧠 কার্ডের অবস্থান মনে রাখুন',
      '✅ জোড়া মিলিয়ে স্কোর করুন',
      '❌ ভুল হলে আবার উল্টে যায়',
      '🏆 বেশি জোড়া যে মেলাবে জয়',
    ],
  );

  static const connectFour = GameInstructions(
    titleEn: 'Connect Four',
    titleBn: 'কানেক্ট ফোর',
    rulesEn: [
      '🔴 Drop discs in columns',
      '🎯 Connect 4 in a row to win',
      '↔️ Horizontal, vertical, diagonal',
      '🔄 Take turns dropping',
      '🧠 Block opponent\'s moves',
    ],
    rulesBn: [
      '🔴 কলামে চাকতি ফেলুন',
      '🎯 ৪টি সারিতে মিলিয়ে জিতুন',
      '↔️ আড়াআড়ি, লম্বা বা তির্যক',
      '🔄 পালা করে ফেলুন',
      '🧠 প্রতিপক্ষকে আটকান',
    ],
  );

  static const dotsBoxes = GameInstructions(
    titleEn: 'Dots & Boxes',
    titleBn: 'ডটস অ্যান্ড বক্সেস',
    rulesEn: [
      '📝 Draw lines between dots',
      '📦 Complete box to score',
      '🔄 Extra turn for completing box',
      '🎯 Most boxes wins',
      '🧠 Plan your moves wisely',
    ],
    rulesBn: [
      '📝 বিন্দুর মধ্যে লাইন টানুন',
      '📦 বাক্স সম্পূর্ণ করে স্কোর করুন',
      '🔄 বাক্স করলে আবার সুযোগ',
      '🎯 বেশি বাক্স যে করবে জয়',
      '🧠 বুদ্ধি করে চাল দিন',
    ],
  );

  static const simonSays = GameInstructions(
    titleEn: 'Simon Says',
    titleBn: 'সাইমন সেজ',
    rulesEn: [
      '👀 Watch the color sequence',
      '🔴🟢🔵🟡 Remember the order',
      '👆 Tap colors in same order',
      '📈 Sequence gets longer',
      '❌ Wrong tap = Game Over',
    ],
    rulesBn: [
      '👀 রঙের ক্রম দেখুন',
      '🔴🟢🔵🟡 ক্রম মনে রাখুন',
      '👆 একই ক্রমে ট্যাপ করুন',
      '📈 ধীরে ধীরে লম্বা হয়',
      '❌ ভুল ট্যাপ = গেম ওভার',
    ],
  );

  static const reactionGame = GameInstructions(
    titleEn: 'Reaction Game',
    titleBn: 'রিঅ্যাকশন গেম',
    rulesEn: [
      '🔴 Wait for GREEN light',
      '🟢 Tap as fast as you can',
      '⚡ Fastest reaction wins',
      '❌ Too early = instant lose',
      '🏆 Best of rounds wins',
    ],
    rulesBn: [
      '🔴 সবুজ আলোর জন্য অপেক্ষা করুন',
      '🟢 দ্রুত ট্যাপ করুন',
      '⚡ দ্রুততম প্রতিক্রিয়া জয়',
      '❌ তাড়াতাড়ি ট্যাপ = হার',
      '🏆 সেরা রাউন্ড জয়',
    ],
  );

  static const numberGuess = GameInstructions(
    titleEn: 'Number Guess',
    titleBn: 'নম্বর গেস',
    rulesEn: [
      '🎯 Find secret number 1-100',
      '⬆️ "Too Low" = guess higher',
      '⬇️ "Too High" = guess lower',
      '🔄 Take turns guessing',
      '🏆 First to find it wins',
    ],
    rulesBn: [
      '🎯 ১-১০০ এর গোপন সংখ্যা খুঁজুন',
      '⬆️ "কম" = বড় অনুমান করুন',
      '⬇️ "বেশি" = ছোট অনুমান করুন',
      '🔄 পালা করে অনুমান করুন',
      '🏆 যে আগে পাবে সে জিতবে',
    ],
  );

  static const bounceTales = GameInstructions(
    titleEn: 'Bounce Tales',
    titleBn: 'বাউন্স টেলস',
    rulesEn: [
      '⬅️➡️ Move left/right',
      '⬆️ Jump to platforms',
      '🪙 Collect coins',
      '🚩 Reach flag to win',
      '💀 Avoid falling & spikes',
    ],
    rulesBn: [
      '⬅️➡️ বাম/ডানে যান',
      '⬆️ প্ল্যাটফর্মে লাফ দিন',
      '🪙 কয়েন সংগ্রহ করুন',
      '🚩 পতাকায় পৌঁছে জিতুন',
      '💀 পড়া ও কাঁটা এড়িয়ে চলুন',
    ],
  );

  static const diamondRush = GameInstructions(
    titleEn: 'Diamond Rush',
    titleBn: 'ডায়মন্ড রাশ',
    rulesEn: [
      '💎 Collect all diamonds',
      '🔑 Find key to open exit',
      '🚪 Reach exit to win',
      '🔥 Avoid fire & spikes',
      '🕷️ Watch out for enemies',
    ],
    rulesBn: [
      '💎 সব হীরা সংগ্রহ করুন',
      '🔑 চাবি পেয়ে দরজা খুলুন',
      '🚪 বের হয়ে জিতুন',
      '🔥 আগুন ও কাঁটা এড়িয়ে চলুন',
      '🕷️ শত্রু থেকে সাবধান',
    ],
  );

  static const arkanoid = GameInstructions(
    titleEn: 'Arkanoid',
    titleBn: 'আরকানয়েড',
    rulesEn: [
      '⬅️➡️ Move paddle to hit ball',
      '🧱 Break all bricks to win',
      '⭐ Catch power-ups for bonuses',
      '❤️ You have 3 lives',
      '🎯 Don\'t let the ball fall!',
    ],
    rulesBn: [
      '⬅️➡️ প্যাডেল সরিয়ে বল মারুন',
      '🧱 সব ইট ভেঙে জিতুন',
      '⭐ বোনাসের জন্য পাওয়ার-আপ ধরুন',
      '❤️ আপনার ৩টি জীবন আছে',
      '🎯 বল পড়তে দেবেন না!',
    ],
  );

  static const tetris = GameInstructions(
    titleEn: 'Tetris',
    titleBn: 'টেট্রিস',
    rulesEn: [
      '⬅️➡️ Move pieces left/right',
      '⬆️ Rotate pieces',
      '⬇️ Soft drop, Space = Hard drop',
      '🧱 Complete lines to clear them',
      '4️⃣ Clear 4 lines = TETRIS!',
    ],
    rulesBn: [
      '⬅️➡️ টুকরা বাম/ডানে সরান',
      '⬆️ টুকরা ঘোরান',
      '⬇️ ধীরে পড়ান, Space = দ্রুত পড়ান',
      '🧱 সম্পূর্ণ লাইন মুছে দিন',
      '4️⃣ ৪ লাইন মুছলে = টেট্রিস!',
    ],
  );

  static const candyCrush = GameInstructions(
    titleEn: 'Candy Crush',
    titleBn: 'ক্যান্ডি ক্রাশ',
    rulesEn: [
      '👆 Swipe to swap adjacent candies',
      '3️⃣ Match 3+ same colors to crush',
      '4️⃣ Match 4 = Striped candy (clears row/col)',
      '5️⃣ Match 5 = Color Bomb (clears all of one color)',
      '🎯 Reach target score before moves run out!',
    ],
    rulesBn: [
      '👆 পাশের ক্যান্ডি অদলবদল করুন',
      '3️⃣ ৩+ একই রঙ মিলিয়ে ক্রাশ করুন',
      '4️⃣ ৪টা মেলালে = স্ট্রাইপড (সারি/কলাম মুছে)',
      '5️⃣ ৫টা মেলালে = কালার বম্ব (এক রঙ মুছে)',
      '🎯 মুভ শেষ হওয়ার আগে টার্গেট স্কোর করুন!',
    ],
  );

  static const spaceShooter = GameInstructions(
    titleEn: 'Space Shooter',
    titleBn: 'স্পেস শুটার',
    rulesEn: [
      'Drag left/right to move your ship',
      'Auto-fire destroys aliens',
      'Collect power-ups for upgrades',
      'Avoid enemy bullets and collisions',
      'Survive and get the high score!',
    ],
    rulesBn: [
      'জাহাজ সরাতে বাম/ডান টানুন',
      'অটো-ফায়ার শত্রুদের ধ্বংস করে',
      'আপগ্রেডের জন্য পাওয়ার-আপ সংগ্রহ করুন',
      'শত্রু গুলি এবং সংঘর্ষ এড়িয়ে চলুন',
      'বেঁচে থাকুন এবং হাই স্কোর করুন!',
    ],
  );
}

/// Reusable How to Play dialog
void showHowToPlay(BuildContext context, GameInstructions instructions) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFFFFFBF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcons.help(size: 28, color: const Color(0xFFFF8C42)),
                const SizedBox(width: 10),
                Text(
                  'How to Play',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${instructions.titleEn} | ${instructions.titleBn}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            
            // English Rules
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🇬🇧 English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...instructions.rulesEn.map((rule) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(rule, style: const TextStyle(fontSize: 13)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Bangla Rules
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🇧🇩 বাংলা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...instructions.rulesBn.map((rule) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(rule, style: const TextStyle(fontSize: 13)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Got it! বুঝেছি!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
}
