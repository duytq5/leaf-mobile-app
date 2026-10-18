import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
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
        // An empty list shows its failure in the body, so the snackbar is for
        // the rest: a failed download or delete.
        listenWhen: (previous, current) =>
            current.failure != null &&
            current.entries.isNotEmpty &&
            previous.failure != current.failure,
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(content: Text(context.l10n.failure(state.failure!))),
              );
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
                context.l10n.appTitle,
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
          Text(
            context.l10n.catalogTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.catalogIntro,
            style: const TextStyle(
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

    if (state.entries.isEmpty) return _NoModel(failure: state.failure);

    final bloc = context.read<ModelCatalogBloc>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        return ModelCard(
          entry: entry,
          selected:
              entry.installed != null && entry.id == state.selected?.id,
          downloading: state.isDownloading(entry.id),
          progress: state.progress[entry.id],
          onTap: () => bloc.add(ModelSelected(entry.id)),
          onDownload: () => bloc.add(ModelDownloadRequested(entry.id)),
          onDelete: () async {
            if (await _confirmDelete(context, entry.displayName)) {
              bloc.add(ModelDeleteRequested(entry.id));
            }
          },
        );
      },
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.catalogDeleteTitle(name)),
      content: Text(l10n.catalogDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The app ships no model, so before the platform releases one, or offline
/// with nothing downloaded, the list is empty.
class _NoModel extends StatelessWidget {
  const _NoModel({required this.failure});

  /// Why the list could not load. Null means the platform has no release.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = failure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              l10n.catalogEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              reason == null ? l10n.catalogEmptyBody : l10n.failure(reason),
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
              child: Text(
                l10n.tryAgain,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
    final l10n = context.l10n;
    final selected = state.selected;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: selected != null
              ? l10n.catalogUseModel(selected.displayName)
              : state.entries.isEmpty
              ? l10n.catalogChooseModel
              : l10n.catalogDownloadToStart,
          onPressed: selected == null ? null : () => onContinue(selected),
        ),
      ),
    );
  }
}
