import 'package:equatable/equatable.dart';

import 'leaf_model.dart';

/// Where a model of the list stands on this phone.
enum ModelStatus { notDownloaded, downloaded, updateAvailable }

/// One model of the list: a dataset the platform released, a model on disk,
/// or both.
class CatalogEntry extends Equatable {
  const CatalogEntry({
    required this.id,
    required this.displayName,
    required this.cropName,
    this.releasedVersion,
    this.installed,
  });

  /// The platform's dataset name, for example `rocole`.
  final String id;

  /// The name the card shows, for example `Lá cà phê (RoCoLe)`.
  final String displayName;

  /// The readable name of the crop, for example `Cà phê`.
  final String cropName;

  /// The current release on the platform. It is null offline, or when the
  /// platform no longer lists the dataset.
  final int? releasedVersion;

  /// The model on this phone, or null when the user has not downloaded it.
  final LeafModel? installed;

  ModelStatus get status {
    final model = installed;
    if (model == null) return ModelStatus.notDownloaded;
    if (releasedVersion != null && model.version != '$releasedVersion') {
      return ModelStatus.updateAvailable;
    }
    return ModelStatus.downloaded;
  }

  CatalogEntry withInstalled(LeafModel? model) => CatalogEntry(
    id: id,
    displayName: displayName,
    cropName: cropName,
    releasedVersion: releasedVersion,
    installed: model,
  );

  @override
  List<Object?> get props => [
    id,
    displayName,
    cropName,
    releasedVersion,
    installed,
  ];
}
