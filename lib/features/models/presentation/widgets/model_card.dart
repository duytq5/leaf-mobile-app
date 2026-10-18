import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/catalog_entry.dart';

/// One card of the picker.
///
/// The chips come from `model.labelNames`, which comes from the manifest. A card
/// never holds a label in its code. A model that is not on the phone has no
/// manifest yet, so its card shows the release and a download button.
class ModelCard extends StatelessWidget {
  const ModelCard({
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
    this.downloading = false,
    this.progress,
    super.key,
  });

  final CatalogEntry entry;
  final bool selected;
  final bool downloading;

  /// A fraction from 0 to 1, or null while the size is unknown.
  final double? progress;

  final VoidCallback onTap;

  /// Download, or update to the current release.
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final model = entry.installed;
    if (model != null) {
      final version = model.version;
      return [
        model.dataset,
        int.tryParse(version) != null ? 'v$version' : version,
        l10n.modelLabelCount(model.labelCount),
      ].join(' · ');
    }
    final release = entry.releasedVersion;
    return [
      entry.cropName,
      if (release != null) 'v$release',
      l10n.modelNotDownloaded,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final model = entry.installed;
    final subtitle = _subtitle(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${entry.displayName}, $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (model != null) ...[
                    const SizedBox(width: 12),
                    _SelectionDot(selected: selected),
                  ],
                ],
              ),
              if (model != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in model.labelNames)
                      _LabelChip(label: label, highlighted: selected),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              downloading
                  ? _Progress(progress: progress)
                  : _Actions(
                      entry: entry,
                      onDownload: onDownload,
                      onDelete: onDelete,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final share = progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: share,
          color: AppColors.primary,
          backgroundColor: AppColors.tint,
        ),
        const SizedBox(height: 6),
        Text(
          share == null
              ? context.l10n.modelDownloading
              : context.l10n.modelDownloadingPercent((share * 100).round()),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.entry,
    required this.onDownload,
    required this.onDelete,
  });

  final CatalogEntry entry;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = entry.status;
    return Row(
      children: [
        if (status == ModelStatus.notDownloaded)
          _ActionButton(
            label: l10n.modelDownload,
            icon: Icons.download_outlined,
            onPressed: onDownload,
            filled: true,
          ),
        if (status == ModelStatus.updateAvailable)
          _ActionButton(
            label: l10n.modelUpdateTo('${entry.releasedVersion}'),
            icon: Icons.system_update_alt,
            onPressed: onDownload,
            filled: true,
          ),
        const Spacer(),
        if (status != ModelStatus.notDownloaded)
          _ActionButton(
            label: l10n.delete,
            icon: Icons.delete_outline,
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colour = filled ? AppColors.primary : AppColors.muted;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colour,
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(Icons.check, size: 16, color: AppColors.onPrimary),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.tint : AppColors.chipGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: highlighted ? AppColors.primaryDark : AppColors.textStrong,
        ),
      ),
    );
  }
}
