import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BluePatternBackground extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  final bool showTopCircles;
  final bool showBottomCircles;

  final bool compactTopCircles;

  final double topMinStrokeWidth;
  final double topMaxStrokeWidth;
  final double topTaperPower;

  final double bottomMinStrokeWidth;
  final double bottomMaxStrokeWidth;
  final double bottomTaperPower;

  const BluePatternBackground({
    super.key,
    required this.child,
    this.borderRadius,

    this.showTopCircles = true,
    this.showBottomCircles = true,

    this.compactTopCircles = false,

    this.topMinStrokeWidth = 0.01,
    this.topMaxStrokeWidth = 5.4,
    this.topTaperPower = 6.4,

    this.bottomMinStrokeWidth = 0.25,
    this.bottomMaxStrokeWidth = 25.6,
    this.bottomTaperPower = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ColoredBox(
        color: AppColors.primary,
        child: CustomPaint(
          painter: _BluePatternPainter(
            showTopCircles: showTopCircles,
            showBottomCircles: showBottomCircles,
            compactTopCircles: compactTopCircles,

            topMinStrokeWidth: topMinStrokeWidth,
            topMaxStrokeWidth: topMaxStrokeWidth,
            topTaperPower: topTaperPower,

            bottomMinStrokeWidth: bottomMinStrokeWidth,
            bottomMaxStrokeWidth: bottomMaxStrokeWidth,
            bottomTaperPower: bottomTaperPower,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BluePatternPainter extends CustomPainter {
  final bool showTopCircles;
  final bool showBottomCircles;

  final bool compactTopCircles;

  final double topMinStrokeWidth;
  final double topMaxStrokeWidth;
  final double topTaperPower;

  final double bottomMinStrokeWidth;
  final double bottomMaxStrokeWidth;
  final double bottomTaperPower;

  _BluePatternPainter({
    required this.showTopCircles,
    required this.showBottomCircles,
    required this.compactTopCircles,

    required this.topMinStrokeWidth,
    required this.topMaxStrokeWidth,
    required this.topTaperPower,

    required this.bottomMinStrokeWidth,
    required this.bottomMaxStrokeWidth,
    required this.bottomTaperPower,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showTopCircles) {
      if (compactTopCircles) {
        _drawDashboardTopCircles(canvas, size);
      } else {
        _drawWelcomeTopCircles(canvas, size);
      }
    }

    if (showBottomCircles) {
      _drawBottomLeftCircles(canvas, size);
    }
  }

  void _drawWelcomeTopCircles(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.10, -size.height * 0.04);

    for (final radius in [
      size.width * 0.23,
      size.width * 0.42,
      size.width * 0.61,
      size.width * 0.80,
      size.width * 0.99,
    ]) {
      _drawTaperedCircle(
        canvas,
        center: center,
        radius: radius,
        minStrokeWidth: topMinStrokeWidth,
        maxStrokeWidth: topMaxStrokeWidth,
        taperPower: topTaperPower,
        segments: 500,
      );
    }
  }

  void _drawDashboardTopCircles(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.00, -size.height * 0.03);

    for (final radius in [
      size.width * 0.12,
      size.width * 0.23,
      size.width * 0.34,
      size.width * 0.45,
      size.width * 0.56,
    ]) {
      _drawTaperedCircle(
        canvas,
        center: center,
        radius: radius,

        minStrokeWidth: 0.0000001,
        maxStrokeWidth: 3.5,
        taperPower: 4.5,

        segments: 500,
      );
    }
  }

  void _drawBottomLeftCircles(Canvas canvas, Size size) {
    final center = Offset(-size.width * 0.18, size.height * 1.03);

    for (final radius in [
      size.width * 0.32,
      size.width * 0.52,
      size.width * 0.72,
      size.width * 0.92,
    ]) {
      _drawTaperedCircle(
        canvas,
        center: center,
        radius: radius,
        minStrokeWidth: bottomMinStrokeWidth,
        maxStrokeWidth: bottomMaxStrokeWidth,
        taperPower: bottomTaperPower,
        segments: 500,
      );
    }
  }

  void _drawTaperedCircle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double minStrokeWidth,
    required double maxStrokeWidth,
    required double taperPower,
    required int segments,
  }) {
    for (int i = 0; i < segments; i++) {
      final progress = i / segments;

      final angle = progress * math.pi * 2;

      final rawStrength = 0.5 - 0.5 * math.cos(progress * math.pi * 2);

      final strength = math.pow(rawStrength, taperPower).toDouble();

      final strokeWidth =
          minStrokeWidth + strength * (maxStrokeWidth - minStrokeWidth);

      final paint = Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        math.pi * 2 / segments,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BluePatternPainter oldDelegate) {
    return oldDelegate.showTopCircles != showTopCircles ||
        oldDelegate.showBottomCircles != showBottomCircles ||
        oldDelegate.compactTopCircles != compactTopCircles ||
        oldDelegate.topMinStrokeWidth != topMinStrokeWidth ||
        oldDelegate.topMaxStrokeWidth != topMaxStrokeWidth ||
        oldDelegate.topTaperPower != topTaperPower ||
        oldDelegate.bottomMinStrokeWidth != bottomMinStrokeWidth ||
        oldDelegate.bottomMaxStrokeWidth != bottomMaxStrokeWidth ||
        oldDelegate.bottomTaperPower != bottomTaperPower;
  }
}
