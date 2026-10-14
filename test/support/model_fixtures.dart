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

/// A manifest as the platform releases it, with 2 classes.
ModelManifest platformManifest({
  required int version,
  String model = 'leaf-disease-rocole',
}) {
  return ModelManifest.fromPlatformJson({
    'model': model,
    'version': version,
    'format': 'onnx',
    'sha256': 'ab' * 32,
    'size_bytes': 3,
    'preprocess': {
      'input_size': [256, 256],
      'mean': [0.485, 0.456, 0.406],
      'std': [0.229, 0.224, 0.225],
    },
    'labels': [
      {'code': 'healthy', 'display_name': 'Healthy'},
      {'code': 'rust', 'display_name': 'Rust'},
    ],
  });
}

/// A model the app downloaded from the platform.
final releasedModel = LeafModel(
  id: 'rocole',
  datasetName: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  dataset: 'Cà phê',
  manifest: platformManifest(version: 3),
  modelFile: '/models/rocole/3/model.onnx',
);
