import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/leafscan_mark.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/leaf_model.dart';
import '../bloc/model_catalog_bloc.dart';
import '../widgets/model_card.dart';

/// Artboard `1 · Choose model`.
class ModelCatalogPage extends StatelessWidget {
  const ModelCatalogPage({required this.onContinue, super.key});

  /// Runs with the selected model when the user taps the button.
  final void Function(LeafModel model) onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: BlocConsumer<ModelCatalogBloc, ModelCatalogState>(
        listenWhen: (previous, current) =>
            current.status == ModelCatalogStatus.failure &&
            previous.message != current.message,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _Header(),
                Expanded(child: _Body(state: state)),
                _Footer(state: state, onContinue: onContinue),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LeafScanMark(size: 26, veinColor: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'LeafScan',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.17,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose an AI model',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each model recognises a different crop. Check its labels before '
            'scanning.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.onPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ModelCatalogState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == ModelCatalogStatus.loading ||
        state.status == ModelCatalogStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.models.isEmpty) return _NoModel(message: state.message);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.models.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final model = state.models[index];
        return ModelCard(
          model: model,
          selected: model.id == state.selected?.id,
          onTap: () =>
              context.read<ModelCatalogBloc>().add(ModelSelected(model.id)),
        );
      },
    );
  }
}

/// The app ships no model, so before the platform releases one, or offline
/// with nothing downloaded, the list is empty.
class _NoModel extends StatelessWidget {
  const _NoModel({required this.message});

  /// Why the list could not load. Null means the platform has no release.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'No models yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'No crop has a released model yet. Check again later.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<ModelCatalogBloc>().add(
                const ModelsRequested(),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 44),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onContinue});

  final ModelCatalogState state;
  final void Function(LeafModel model) onContinue;

  @override
  Widget build(BuildContext context) {
    final selected = state.selected;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: selected == null
              ? 'Choose a model'
              : 'Use ${selected.displayName} model',
          onPressed: selected == null ? null : () => onContinue(selected),
        ),
      ),
    );
  }
}
