import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const FountainApp());

class FountainApp extends StatelessWidget {
  const FountainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FountainScreen(),
    );
  }
}

class FountainScreen extends StatefulWidget {
  const FountainScreen({super.key});

  @override
  State<FountainScreen> createState() => _FountainScreenState();
}

class _FountainScreenState extends State<FountainScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<FountainStream> _streams;

  bool _isRunning = false;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _streams = _createFountainStreams();
    _ticker = createTicker(_tick);
  }

  List<FountainStream> _createFountainStreams() {
    const center = Offset(200, 400);
    const radius = 100.0;
    final List<FountainStream> list = [];

    for (int i = 0; i < 24; i++) {
      final angle = 2 * pi * i / 24;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      final origin = Offset(dx, dy);

      final delay = i * 0.1;
      list.add(FountainStream(origin, i, delay));
    }

    return list;
  }

  void _tick(Duration elapsed) {
    if (!_isRunning) return;
    _elapsed = elapsed;
    setState(() {
      for (final stream in _streams) {
        stream.update(_elapsed);
      }
    });
  }

  void _start() {
    if (!_ticker.isActive) _ticker.start();
    setState(() {
      _isRunning = true;
    });
  }

  void _pause() {
    setState(() {
      _isRunning = false;
    });
  }

  void _stop() {
    setState(() {
      _isRunning = false;
      _streams = _createFountainStreams(); // Reset all
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomPaint(
            painter: LaminarFountainPainter(_streams),
            size: Size.infinite,
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pause,
                  icon: const Icon(Icons.pause),
                  label: const Text("Pause"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StreamParticle {
  Offset position;
  double progress;
  double alpha;

  StreamParticle({required this.position, required this.progress, this.alpha = 1.0});
}

class FountainStream {
  final Offset origin;
  final int count = 20;
  final List<StreamParticle> particles = [];
  final double baseHeight;
  final double delay;
  double time = 0.0;

  FountainStream(this.origin, int index, this.delay)
      : baseHeight = 70 + (index * 2.5) {
    for (int i = 0; i < count; i++) {
      particles.add(StreamParticle(position: origin, progress: i / count));
    }
  }

  void update(Duration elapsed) {
    time = elapsed.inMilliseconds / 1000.0;
    final wave = 0.5 + 0.5 * sin((time - delay) * 2 * pi / 2);
    final height = baseHeight * wave;

    for (var p in particles) {
      p.progress += 0.015;
      if (p.progress > 1.0) p.progress = 0;

      final t = p.progress;
      final y = -height * (4 * t * (1 - t));
      p.position = origin.translate(0, y);
      p.alpha = 1.0 - t;
    }
  }
}

class LaminarFountainPainter extends CustomPainter {
  final List<FountainStream> streams;

  LaminarFountainPainter(this.streams);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.color = Colors.teal;
    canvas.drawCircle(const Offset(200, 400), 140, paint);

    paint.color = Colors.grey[850]!;
    canvas.drawCircle(const Offset(200, 400), 120, paint);

    for (final stream in streams) {
      paint.color = Colors.amber;
      canvas.drawCircle(stream.origin, 4, paint);

      for (int i = 0; i < stream.particles.length - 1; i++) {
        final p1 = stream.particles[i];
        final p2 = stream.particles[i + 1];

        final gradientPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlueAccent.withOpacity(p1.alpha),
              Colors.cyanAccent.withOpacity(p2.alpha),
            ],
          ).createShader(Rect.fromPoints(p1.position, p2.position))
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1.position, p2.position, gradientPaint);
      }

      final glowPaint = Paint()
        ..color = Colors.blueAccent.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(stream.origin, 6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
