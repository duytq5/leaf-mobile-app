import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/screen_scaffold.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Artboard `0b · Full terms`.
class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static List<(String, String)> _sections(AppLocalizations l10n) => [
    (l10n.termsUploadsHeading, l10n.termsUploadsBody),
    (l10n.termsWhyHeading, l10n.termsWhyBody),
    (l10n.termsWhenHeading, l10n.termsWhenBody),
    (l10n.termsNotCollectedHeading, l10n.termsNotCollectedBody),
    (l10n.termsRetentionHeading, l10n.termsRetentionBody),
    (l10n.termsStopHeading, l10n.termsStopBody),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = _sections(l10n);
    return ScreenScaffold(
      title: l10n.termsTitle,
      onBack: () => Navigator.of(context).pop(),
      backLabel: l10n.termsBack,
      body: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 22),
          itemBuilder: (context, index) {
            final (heading, body) = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.muted,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
