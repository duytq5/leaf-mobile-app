import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'classifier.dart';
import 'model_manifest.dart';

const String kManifestAsset = 'assets/models/manifest.json';
const String kModelAsset = 'assets/models/model.onnx';

/// Loads the model that ships in the assets of the app.
///
/// The function reads [kManifestAsset] first. The manifest gives the input
/// size, the normalization values and the label order. The app does not hold
/// these values in its code.
///
/// Throws [ClassifierException] when the manifest or the model is absent.
Future<Classifier> loadBundledClassifier() async {
  final String text;
  try {
    text = await rootBundle.loadString(kManifestAsset);
  } catch (_) {
    throw const ClassifierException('the file $kManifestAsset is absent');
  }

  final ModelManifest manifest;
  try {
    manifest = ModelManifest.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
  } on ManifestFormatException catch (error) {
    throw ClassifierException('the manifest is not valid: ${error.message}');
  }

  return Classifier.loadFromAsset(modelAsset: kModelAsset, manifest: manifest);
}
