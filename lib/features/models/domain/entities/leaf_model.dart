import 'package:equatable/equatable.dart';

import 'model_manifest.dart';

/// One model the user can select.
///
/// The labels come from the manifest of the model. No screen holds a label.
class LeafModel extends Equatable {
  const LeafModel({
    required this.id,
    required this.displayName,
    required this.dataset,
    required this.manifest,
    required this.modelAsset,
  });

  /// The id in the catalog, for example `coffee_rocole`.
  final String id;

  /// The name the picker shows, for example `Coffee Leaf`.
  final String displayName;

  /// The dataset the card names, for example `RoCoLe`.
  final String dataset;

  final ModelManifest manifest;

  /// The asset key of the ONNX file.
  final String modelAsset;

  /// The version of the weights, for example `fold-1-best`.
  String get version => manifest.version;

  /// The classes of the model, in the output order.
  List<String> get labels => manifest.labels;

  int get labelCount => labels.length;

  /// The line under the name of the card.
  String get subtitle => '$dataset · $version · $labelCount labels';

  @override
  List<Object?> get props => [id, displayName, dataset, modelAsset, labels];
}
