import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Paints the dashed outline of the photo drop area.
class DashedBorder extends StatelessWidget {
  const DashedBorder({required this.child, this.radius = 18, super.key});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(radius: radius),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dashed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in outline.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
