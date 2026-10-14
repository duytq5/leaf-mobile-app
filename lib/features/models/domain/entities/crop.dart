import 'package:equatable/equatable.dart';

/// A dataset of a crop that has a released model.
class CropDataset extends Equatable {
  const CropDataset({
    required this.name,
    required this.displayName,
    required this.version,
  });

  /// The machine name, for example `rocole`. The app passes it to
  /// `GET /v1/devices/config`.
  final String name;

  /// The name the screen shows, for example `Lá cà phê (RoCoLe)`.
  final String displayName;

  /// The current release. The app compares it with its cached model.
  final int version;

  @override
  List<Object?> get props => [name, displayName, version];
}

/// A crop the home screen lists, for example coffee.
class Crop extends Equatable {
  const Crop({
    required this.code,
    required this.displayName,
    required this.datasets,
    this.description,
  });

  final String code;
  final String displayName;
  final String? description;

  /// At least one dataset. A crop with no release is not listed.
  final List<CropDataset> datasets;

  @override
  List<Object?> get props => [code, displayName, description, datasets];
}
