import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/model_manifest.dart';

/// A manifest with the transform of the training code.
ModelManifest manifestWith({
  required String version,
  required List<String> labels,
}) {
  return ModelManifest(
    modelId: 'fastvit_t8',
    version: version,
    input: const InputSpec(
      width: 256,
      height: 256,
      layout: 'NCHW',
      mean: [0.485, 0.456, 0.406],
      std: [0.229, 0.224, 0.225],
      resizeShortest: 292,
    ),
    labels: labels,
  );
}

/// The coffee model, with the 3 classes the trained model really has.
final coffeeModel = LeafModel(
  id: 'coffee_rocole',
  displayName: 'Coffee Leaf',
  dataset: 'RoCoLe',
  manifest: manifestWith(
    version: 'fold-1-best',
    labels: const [
      'coffee___healthy',
      'coffee___red_spider_mite',
      'coffee___rust',
    ],
  ),
  modelAsset: 'assets/models/coffee/model.onnx',
);

/// The durian model, with 6 classes.
final durianModel = LeafModel(
  id: 'durian',
  displayName: 'Durian Leaf',
  dataset: 'Vietnamese durian',
  manifest: manifestWith(
    version: 'fold-3-best',
    labels: const [
      'Leaf_Algal',
      'Leaf_Blight',
      'Leaf_Colletotrichum',
      'Leaf_Healthy',
      'Leaf_Phomopsis',
      'Leaf_Rhizoctonia',
    ],
  ),
  modelAsset: 'assets/models/durian/model.onnx',
);
