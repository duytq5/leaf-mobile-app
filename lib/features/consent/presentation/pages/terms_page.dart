import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/screen_scaffold.dart';

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

  static const _sections = <(String, String)>[
    (
      'What the app uploads',
      'The app uploads every photo you take or choose. The app also uploads the '
          'prediction of the model and a score that says how certain the model is.',
    ),
    (
      'Why the app uploads a photo',
      'The photos build the training set of the next model. A photo from a real '
          'field is more useful than a photo from a laboratory.',
    ),
    (
      'When the app sends a photo',
      'The app keeps each photo and its prediction on the phone. It sends them '
          'when you are signed in and the phone is online.',
    ),
    (
      'What the app does not collect',
      'The app does not ask for your name, your email address or your telephone '
          'number. The app does not read your contacts and does not track your position.',
    ),
    (
      'How long the data stays',
      'The photos stay for the length of the research project. The research team '
          'holds them. The team does not sell them and does not give them to an '
          'advertiser.',
    ),
    (
      'How to stop',
      'Close the app to stop. The app uploads nothing before you agree.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Full terms',
      onBack: () => Navigator.of(context).pop(),
      backLabel: 'Back to the agreement',
      body: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: _sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 22),
          itemBuilder: (context, index) {
            final (heading, body) = _sections[index];
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
