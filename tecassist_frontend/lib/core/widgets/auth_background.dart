import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      backgroundColor: AppColors.primary,

      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _AuthPattern()),

          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

class _AuthPattern extends StatelessWidget {
  const _AuthPattern();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: CustomPaint(painter: _AuthPatternPainter()),
    );
  }
}

class _AuthPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final superior = Offset(size.width * 1.10, -size.height * 0.04);

    final raiosSuperiores = [
      size.width * 0.23,
      size.width * 0.42,
      size.width * 0.61,
      size.width * 0.80,
    ];

    for (final raio in raiosSuperiores) {
      canvas.drawCircle(superior, raio, paint);
    }

    final inferior = Offset(-size.width * 0.18, size.height * 1.03);

    final raiosInferiores = [
      size.width * 0.32,
      size.width * 0.52,
      size.width * 0.72,
      size.width * 0.92,
    ];

    for (final raio in raiosInferiores) {
      canvas.drawCircle(inferior, raio, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
