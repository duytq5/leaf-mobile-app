import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_scaffold.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../domain/entities/scan_result.dart';

/// Artboard `3 · Result`.
///
/// The design shows one label. The thesis needs every number, so the card holds
/// a panel that opens. The screen matches the design while the panel is shut.
class ResultPage extends StatefulWidget {
  const ResultPage({
    required this.result,
    required this.model,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final ScanResult result;
  final LeafModel model;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return ScreenScaffold(
      title: 'Result',
      onBack: widget.onBack,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              result.imageBytes,
              height: 340,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 340,
                color: AppColors.imageGround,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PredictionCard(
            result: result,
            model: widget.model,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: PrimaryButton(label: 'Continue', onPressed: widget.onContinue),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.result,
    required this.model,
    required this.expanded,
    required this.onToggle,
  });

  final ScanResult result;
  final LeafModel model;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final top = result.top;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predicted label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(top.label, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: top.probability,
                    minHeight: 8,
                    backgroundColor: AppColors.imageGround,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${top.percent}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${model.displayName} model · ${result.modelVersion}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                expanded ? 'Hide all scores' : 'Show all scores',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (expanded) _Details(result: result),
        ],
      ),
    );
  }
}

/// The numbers the thesis report needs.
class _Details extends StatelessWidget {
  const _Details({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final scores = result.scores;
    final uncertainty = result.uncertainty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        for (final score in scores)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    score.label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Text(
                  '${(score.probability * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 20),
        _Metric('latency', '${result.latency.inMilliseconds} ms'),
        _Metric('entropy', uncertainty.entropy.toStringAsFixed(4)),
        _Metric(
          'least confidence',
          uncertainty.leastConfidence.toStringAsFixed(4),
        ),
        _Metric('margin', uncertainty.margin.toStringAsFixed(4)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textStrong),
          ),
        ],
      ),
    );
  }
}
