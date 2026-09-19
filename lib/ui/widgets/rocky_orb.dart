import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/rocky_state.dart';

class RockyOrb extends StatefulWidget {
  const RockyOrb({super.key, required this.state});
  final RockyState state;

  @override
  State<RockyOrb> createState() => _RockyOrbState();
}

class _RockyOrbState extends State<RockyOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: const Size(250, 250),
        painter: _OrbPainter(state: widget.state, phase: _controller.value),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.state, required this.phase});
  final RockyState state;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = phase * math.pi * 2;
    final pulse = switch (state) {
      RockyState.listening => 1 + 0.10 * math.sin(t * 2),
      RockyState.thinking => 1 + 0.07 * math.sin(t * 1.5),
      RockyState.speaking => 1 + 0.09 * math.sin(t * 4).abs(),
      RockyState.concerned => 1 + 0.04 * math.sin(t * 1.2),
      _ => 1 + 0.025 * math.sin(t),
    };
    final base = size.shortestSide * 0.29 * pulse;

    final gradient = RadialGradient(
      colors: switch (state) {
        RockyState.listening => [Colors.cyanAccent, Colors.blueAccent, Colors.transparent],
        RockyState.thinking => [Colors.purpleAccent, Colors.indigo, Colors.transparent],
        RockyState.speaking => [Colors.greenAccent, Colors.teal, Colors.transparent],
        RockyState.concerned => [Colors.orangeAccent, Colors.deepOrange, Colors.transparent],
        RockyState.waiting => [Colors.amberAccent, Colors.orange, Colors.transparent],
        RockyState.idle => [Colors.lightBlueAccent, Colors.blueGrey, Colors.transparent],
      },
      stops: const [0, 0.55, 1],
    );

    canvas.drawCircle(center, base * 1.85, Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: base * 1.85)));
    canvas.drawCircle(center, base, Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: base)));

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withOpacity(0.45);
    for (var i = 0; i < 3; i++) {
      final r = base * (1.25 + i * 0.2) + (math.sin(t * (i + 1)) * 4);
      canvas.drawCircle(center, r, ringPaint);
    }

    if (state == RockyState.listening) {
      for (var i = 0; i < 18; i++) {
        final a = (i / 18) * math.pi * 2 + t;
        final amplitude = 8 + 12 * math.sin(t * 3 + i).abs();
        final p1 = center + Offset(math.cos(a), math.sin(a)) * (base * 1.35);
        final p2 = center + Offset(math.cos(a), math.sin(a)) * (base * 1.35 + amplitude);
        canvas.drawLine(p1, p2, Paint()..strokeWidth = 2..color = Colors.cyanAccent.withOpacity(0.7));
      }
    }

    if (state == RockyState.speaking) {
      for (var i = 0; i < 12; i++) {
        final a = (i / 12) * math.pi * 2;
        final r = base * (1.25 + 0.18 * math.sin(t * 4 + i));
        final p = center + Offset(math.cos(a), math.sin(a)) * r;
        canvas.drawCircle(p, 3.0 + 1.5 * math.sin(t * 4 + i).abs(), Paint()..color = Colors.greenAccent.withOpacity(0.85));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => oldDelegate.state != state || oldDelegate.phase != phase;
}
