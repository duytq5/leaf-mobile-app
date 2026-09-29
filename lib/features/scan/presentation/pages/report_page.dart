import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_scaffold.dart';
import '../../domain/entities/label_correction.dart';
import '../bloc/correction_bloc.dart';

/// Artboard `4 · Report wrong label`.
///
/// The rows come from the labels of the model. The design lists four rust
/// levels, which the trained model does not have.
class ReportPage extends StatelessWidget {
  const ReportPage({
    required this.onBack,
    required this.onSubmitted,
    super.key,
  });

  final VoidCallback onBack;

  /// Runs after the app stores the correction.
  final VoidCallback onSubmitted;

  /// The text a row shows for a label.
  static String labelText(String label) =>
      label == LabelCorrection.notSure ? 'Not sure / other' : label;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CorrectionBloc>();
    return BlocConsumer<CorrectionBloc, CorrectionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CorrectionStatus.saved) onSubmitted();
        if (state.status == CorrectionStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final busy = state.status == CorrectionStatus.saving;
        return ScreenScaffold(
          title: 'Report wrong label',
          onBack: busy ? null : onBack,
          backLabel: 'Back to the result',
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Predicted(label: bloc.result.top.label),
              const SizedBox(height: 18),
              const Text(
                'What is the correct label?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              RadioGroup<String>(
                groupValue: state.chosen,
                onChanged: (label) {
                  // The screen ignores a tap while it stores the answer.
                  if (label != null && !busy) {
                    bloc.add(CorrectionLabelChosen(label));
                  }
                },
                child: Column(
                  children: [
                    for (final label in bloc.choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _Choice(
                          label: label,
                          selected: state.chosen == label,
                          onTap: busy
                              ? null
                              : () => bloc.add(CorrectionLabelChosen(label)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: PrimaryButton(
              label: 'Submit correction',
              onPressed: state.chosen == null || busy
                  ? null
                  : () => bloc.add(const CorrectionSubmitted()),
            ),
          ),
        );
      },
    );
  }
}

class _Predicted extends StatelessWidget {
  const _Predicted({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.imageGround,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.eco_outlined,
            size: 28,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI predicted',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.tint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(value: label),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                ReportPage.labelText(label),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primaryDark : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
