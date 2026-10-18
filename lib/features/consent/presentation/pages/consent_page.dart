import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/leafscan_mark.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/consent_bloc.dart';
import 'terms_page.dart';

/// Artboard `0 · Consensus`.
///
/// The screen states three facts, then asks for one agreement. The button stays
/// disabled while the checkbox is clear.
class ConsentPage extends StatelessWidget {
  const ConsentPage({required this.onAccepted, super.key});

  /// Runs after the app stores the agreement.
  final VoidCallback onAccepted;

  static List<(IconData, String, String)> _points(AppLocalizations l10n) => [
    (
      Icons.cloud_upload_outlined,
      l10n.consentUploadTitle,
      l10n.consentUploadBody,
    ),
    (Icons.layers_outlined, l10n.consentTrainTitle, l10n.consentTrainBody),
    (Icons.wifi_outlined, l10n.consentOnlineTitle, l10n.consentOnlineBody),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConsentBloc, ConsentState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ConsentStatus.accepted) onAccepted();
        if (state.status == ConsentStatus.failure && state.failure != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.failure(state.failure!))),
            );
        }
      },
      builder: (context, state) {
        final busy = state.status == ConsentStatus.loading;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    children: [
                      const _Header(),
                      const SizedBox(height: 24),
                      for (final (icon, title, body) in _points(context.l10n)) ...[
                        _Point(icon: icon, title: title, body: body),
                        const SizedBox(height: 18),
                      ],
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TermsPage(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(
                            context.l10n.consentReadTerms,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _Agreement(state: state, busy: busy),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LeafScanTile(),
        const SizedBox(height: 12),
        Text(
          context.l10n.consentTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.consentIntro,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Agreement extends StatelessWidget {
  const _Agreement({required this.state, required this.busy});

  final ConsentState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConsentBloc>();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: busy ? null : () => bloc.add(ConsentToggled(!state.checked)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: state.checked,
                    onChanged: busy
                        ? null
                        : (value) => bloc.add(ConsentToggled(value ?? false)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        context.l10n.consentCheckbox,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: context.l10n.consentAgree,
            onPressed: state.checked && !busy
                ? () => bloc.add(const ConsentAccepted())
                : null,
          ),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: busy ? null : () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: Text(
                context.l10n.consentCloseApp,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
