import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CinematicHeroBackground extends StatefulWidget {
  final Widget child;

  const CinematicHeroBackground({
    super.key,
    required this.child,
  });

  @override
  State<CinematicHeroBackground> createState() => _CinematicHeroBackgroundState();
}

class _CinematicHeroBackgroundState extends State<CinematicHeroBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark midnight highway gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071426), // Deepest Navy
                Color(0xFF0F2B48), // Brand Primary
                Color(0xFF091E35), // Dark Midnight
                Color(0xFF132F4C),
              ],
              stops: [0.0, 0.4, 0.75, 1.0],
            ),
          ),
        ),

        // Animated Perspective Highway Light Streaks
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _HighwayPerspectivePainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Ambient glowing orbs (amber highway illumination & emerald trust glow)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            final dx1 = math.sin(t) * 80;
            final dy1 = math.cos(t) * 50;
            final dx2 = math.cos(t * 0.8) * 100;
            final dy2 = math.sin(t * 0.8) * 60;

            return Stack(
              children: [
                Positioned(
                  top: 100 + dy1,
                  left: -50 + dx1,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.18),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80 + dy2,
                  right: -60 + dx2,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.14),
                          AppColors.success.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

class _HighwayPerspectivePainter extends CustomPainter {
  final double progress;

  _HighwayPerspectivePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final horizonY = h * 0.42;
    final vanishingPoint = Offset(w * 0.5, horizonY);

    // Highway boundaries (M-5 Motorway perspective)
    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.01),
          Colors.white.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY));

    final path = Path()
      ..moveTo(vanishingPoint.dx - 40, horizonY)
      ..lineTo(vanishingPoint.dx + 40, horizonY)
      ..lineTo(w * 0.9, h)
      ..lineTo(w * 0.1, h)
      ..close();
    canvas.drawPath(path, roadPaint);

    // Glowing Lane divider lines moving towards camera
    final linePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final numDashes = 7;
    for (int i = 0; i < numDashes; i++) {
      final dashT = (progress + (i / numDashes)) % 1.0;
      final y = horizonY + math.pow(dashT, 2.2) * (h - horizonY);
      final nextY = horizonY + math.pow(math.min(1.0, dashT + 0.07), 2.2) * (h - horizonY);
      final scale = (y - horizonY) / (h - horizonY);

      linePaint.strokeWidth = 1.0 + (scale * 3.5);
      linePaint.color = AppColors.accent.withValues(alpha: 0.05 + (scale * 0.5));

      canvas.drawLine(
        Offset(vanishingPoint.dx, y),
        Offset(vanishingPoint.dx, nextY),
        linePaint,
      );
    }

    // Fast moving traffic light streaks (White headlights on left, Red taillights on right)
    final headLightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;

    final tailLightPaint = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.35)
      ..strokeWidth = 2.5;

    for (int i = 0; i < 4; i++) {
      final streakT = (progress * 1.5 + (i * 0.25)) % 1.0;
      final y1 = horizonY + math.pow(streakT, 2.0) * (h - horizonY);
      final y2 = horizonY + math.pow(math.min(1.0, streakT + 0.15), 2.0) * (h - horizonY);
      final spread1 = (y1 - horizonY) * 0.35;
      final spread2 = (y2 - horizonY) * 0.35;

      // Headlight streak
      canvas.drawLine(
        Offset(vanishingPoint.dx - 20 - spread1, y1),
        Offset(vanishingPoint.dx - 20 - spread2, y2),
        headLightPaint,
      );

      // Taillight streak
      canvas.drawLine(
        Offset(vanishingPoint.dx + 20 + spread1, y1),
        Offset(vanishingPoint.dx + 20 + spread2, y2),
        tailLightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighwayPerspectivePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
