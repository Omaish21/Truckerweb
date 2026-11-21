import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated radar pulse ripple effect for real-time GPS and active fleet status.
class RadarPulse extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;
  final bool isLive;

  const RadarPulse({
    super.key,
    this.size = 28.0,
    this.color = const Color(0xFF2E7D32), // AppColors.success
    this.child,
    this.isLive = true,
  });

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isLive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: widget.child ??
              Container(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarPulsePainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _RadarPulsePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Outer ripple 1
    final progress1 = animationValue;
    final radius1 = maxRadius * progress1;
    final opacity1 = (1.0 - progress1).clamp(0.0, 1.0);
    final paint1 = Paint()
      ..color = color.withValues(alpha: opacity1 * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius1, paint1);

    // Outer ripple 2 (offset)
    final progress2 = (animationValue + 0.5) % 1.0;
    final radius2 = maxRadius * progress2;
    final opacity2 = (1.0 - progress2).clamp(0.0, 1.0);
    final paint2 = Paint()
      ..color = color.withValues(alpha: opacity2 * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius2, paint2);

    // Solid core dot
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.38, corePaint);

    // Glowing core border
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, maxRadius * 0.38, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
