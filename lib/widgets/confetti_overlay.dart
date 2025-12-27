import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Reusable confetti celebration overlay widget
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const ConfettiOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirection: pi / 2, // downward
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.teal,
            ],
            createParticlePath: _drawStar,
          ),
        ),
        // Left side confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirection: -pi / 4, // diagonal right
            maxBlastForce: 7,
            minBlastForce: 3,
            emissionFrequency: 0.03,
            numberOfParticles: 20,
            gravity: 0.15,
            shouldLoop: false,
            colors: const [
              Colors.amber,
              Colors.cyan,
              Colors.deepPurple,
              Colors.lightGreen,
            ],
          ),
        ),
        // Right side confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirection: -3 * pi / 4, // diagonal left
            maxBlastForce: 7,
            minBlastForce: 3,
            emissionFrequency: 0.03,
            numberOfParticles: 20,
            gravity: 0.15,
            shouldLoop: false,
            colors: const [
              Colors.deepOrange,
              Colors.indigo,
              Colors.lime,
              Colors.pinkAccent,
            ],
          ),
        ),
      ],
    );
  }

  /// Custom star-shaped particle
  Path _drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final externalRadius = min(halfWidth, halfHeight);
    final internalRadius = externalRadius / 2.5;
    final degreesPerStep = 36; // 360 / 10 points
    final startDegree = -90; // Start from top

    path.moveTo(
      halfWidth + externalRadius * cos(startDegree * pi / 180),
      halfHeight + externalRadius * sin(startDegree * pi / 180),
    );

    for (int step = 1; step < 10; step++) {
      final radius = step.isEven ? externalRadius : internalRadius;
      final x = halfWidth + radius * cos((startDegree + step * degreesPerStep) * pi / 180);
      final y = halfHeight + radius * sin((startDegree + step * degreesPerStep) * pi / 180);
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }
}

/// Helper mixin for screens that need confetti
mixin ConfettiMixin<T extends StatefulWidget> on State<T> {
  late ConfettiController confettiController;

  void initConfetti() {
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  void disposeConfetti() {
    confettiController.dispose();
  }

  void celebrate() {
    confettiController.play();
  }
}
