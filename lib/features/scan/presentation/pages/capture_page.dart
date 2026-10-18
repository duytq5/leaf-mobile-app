import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_scaffold.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../domain/entities/image_source_kind.dart';
import '../../domain/entities/scan_result.dart';
import '../bloc/scan_bloc.dart';
import '../widgets/dashed_border.dart';

/// Artboard `2 · Add photo`.
class CapturePage extends StatelessWidget {
  const CapturePage({
    required this.model,
    required this.onBack,
    required this.onResult,
    super.key,
  });

  final LeafModel model;
  final VoidCallback onBack;

  /// Runs when the model finished and produced a result.
  final void Function(ScanResult result) onResult;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanBloc, ScanState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ScanStatus.done && state.result != null) {
          onResult(state.result!);
        }
        if (state.status == ScanStatus.failure && state.failure != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.failure(state.failure!))),
            );
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final bloc = context.read<ScanBloc>();
        void scan(ImageSourceKind source) =>
            bloc.add(ScanImageRequested(source: source, model: model));

        return ScreenScaffold(
          title: l10n.captureTitle,
          onBack: state.busy ? null : onBack,
          backLabel: l10n.captureBack,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModelChip(model: model),
                const SizedBox(height: 16),
                Expanded(child: _DropArea(busy: state.busy)),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.captureTakePhoto,
                  icon: Icons.photo_camera_outlined,
                  onPressed:
                      state.busy ? null : () => scan(ImageSourceKind.camera),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: l10n.captureChooseFromLibrary,
                  icon: Icons.photo_library_outlined,
                  onPressed:
                      state.busy ? null : () => scan(ImageSourceKind.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.model});

  final LeafModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_outlined, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${model.displayName} · ${model.version}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropArea extends StatelessWidget {
  const _DropArea({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DashedBorder(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.ground,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                l10n.captureRunning,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
            ] else ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.captureHeading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: Text(
                  l10n.captureHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
