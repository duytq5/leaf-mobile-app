import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The LeafScan mark: four scan brackets around a leaf with one vein.
///
/// The paths come from the `Logo` artboard of the design. The widget draws them
/// on a 48 unit grid and scales the result to [size].
class LeafScanMark extends StatelessWidget {
  const LeafScanMark({
    required this.size,
    this.markColor = AppColors.onPrimary,
    this.veinColor = AppColors.primary,
    this.bracketColor,
    super.key,
  });

  final double size;

  /// The colour of the brackets and the leaf body.
  final Color markColor;

  /// The colour of the vein. It reads as a cut through the leaf, so it must
  /// match the ground behind the mark.
  final Color veinColor;

  /// The colour of the brackets, when it differs from [markColor].
  final Color? bracketColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(
          leaf: markColor,
          vein: veinColor,
          brackets: bracketColor ?? markColor,
        ),
      ),
    );
  }
}

/// The mark on a rounded tile, as the design draws the app icon.
class LeafScanTile extends StatelessWidget {
  const LeafScanTile({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        // The design uses a radius of 18 on a tile of 72.
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: LeafScanMark(size: size * 0.64),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.leaf,
    required this.vein,
    required this.brackets,
  });

  final Color leaf;
  final Color vein;
  final Color brackets;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    canvas.save();
    canvas.scale(scale);

    const radius = Radius.circular(4);
    final bracketPath = Path()
      // The top left corner.
      ..moveTo(6, 16)
      ..lineTo(6, 10)
      ..arcToPoint(const Offset(10, 6), radius: radius)
      ..lineTo(16, 6)
      // The top right corner.
      ..moveTo(32, 6)
      ..lineTo(38, 6)
      ..arcToPoint(const Offset(42, 10), radius: radius)
      ..lineTo(42, 16)
      // The bottom right corner.
      ..moveTo(42, 32)
      ..lineTo(42, 38)
      ..arcToPoint(const Offset(38, 42), radius: radius)
      ..lineTo(32, 42)
      // The bottom left corner.
      ..moveTo(16, 42)
      ..lineTo(10, 42)
      ..arcToPoint(const Offset(6, 38), radius: radius)
      ..lineTo(6, 32);

    canvas.drawPath(
      bracketPath,
      Paint()
        ..color = brackets
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final leafPath = Path()
      ..moveTo(14, 34)
      ..cubicTo(14, 21, 21, 14, 34, 14)
      ..cubicTo(34, 27, 27, 34, 14, 34)
      ..close();

    canvas.drawPath(leafPath, Paint()..color = leaf);

    canvas.drawLine(
      const Offset(14, 34),
      const Offset(26, 22),
      Paint()
        ..color = vein
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.leaf != leaf ||
      oldDelegate.vein != vein ||
      oldDelegate.brackets != brackets;
}
