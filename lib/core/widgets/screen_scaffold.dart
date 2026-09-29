import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The 64 pixel bar of the design, with a 44 pixel back target.
///
/// The design draws the bar as a row with a bottom border, not as a Material
/// app bar. This widget repeats that shape.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.title,
    required this.body,
    this.onBack,
    this.backLabel = 'Back',
    this.bottom,
    this.background = AppColors.surface,
    super.key,
  });

  final String title;
  final Widget body;

  /// A null callback hides the back target.
  final VoidCallback? onBack;

  /// The label a screen reader reads for the back target.
  final String backLabel;

  /// The block below the body. It does not scroll.
  final Widget? bottom;

  final Color background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      tooltip: backLabel,
                      icon: const Icon(Icons.chevron_left, size: 24),
                      color: AppColors.text,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
