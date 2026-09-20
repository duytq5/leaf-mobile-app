import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'model_manifest.dart';
import 'prediction.dart';
import 'preprocessor.dart';

/// Thrown when the model does not load or does not run.
class ClassifierException implements Exception {
  const ClassifierException(this.message);

  final String message;

  @override
  String toString() => 'ClassifierException: $message';
}

/// Runs the ONNX model on an image.
///
/// Create the classifier one time and keep it. A session creation costs
/// hundreds of milliseconds on a low-performance device.
class Classifier {
  Classifier._(this._session, ModelManifest manifest)
    : _manifest = manifest,
      _preprocessor = Preprocessor(manifest.input);

  final OrtSession _session;
  final ModelManifest _manifest;
  final Preprocessor _preprocessor;

  /// Loads a model that ships in the assets of the app.
  ///
  /// [modelAsset] is an asset key, for example `assets/models/model.onnx`.
  ///
  /// Throws [ClassifierException] when the file is absent or not valid.
  static Future<Classifier> loadFromAsset({
    required String modelAsset,
    required ModelManifest manifest,
  }) async {
    final OrtSession session;
    try {
      session = await OnnxRuntime().createSessionFromAsset(
        modelAsset,
        // Stage 1 uses the CPU only. It gives a repeatable latency number.
        // Add CORE_ML or NNAPI after a measurement shows a benefit.
        options: OrtSessionOptions(providers: [OrtProvider.CPU]),
      );
    } catch (error) {
      throw ClassifierException('the model does not load: $error');
    }

    if (session.inputNames.isEmpty || session.outputNames.isEmpty) {
      await session.close();
      throw const ClassifierException('the model has no input or no output');
    }

    return Classifier._(session, manifest);
  }

  ModelManifest get manifest => _manifest;

  /// Classifies one encoded image, for example a JPEG file.
  ///
  /// Throws [PreprocessException] when the image does not decode.
  /// Throws [ClassifierException] when the model does not run.
  Future<Prediction> classify(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();
    final tensor = _preprocessor.run(imageBytes);
    final input = await OrtValue.fromList(tensor, _inputShape());

    Map<String, OrtValue>? outputs;
    try {
      outputs = await _session.run({_session.inputNames.first: input});

      final output = outputs[_session.outputNames.first];
      if (output == null) {
        throw const ClassifierException('the model returns no output');
      }

      final raw = await output.asFlattenedList();
      stopwatch.stop();

      return Prediction.fromLogits(
        logits: raw.map((v) => (v as num).toDouble()).toList(growable: false),
        labels: _manifest.labels,
        latency: stopwatch.elapsed,
        modelVersion: _manifest.version,
      );
    } on ClassifierException {
      rethrow;
    } catch (error) {
      throw ClassifierException('the model does not run: $error');
    } finally {
      await input.dispose();
      if (outputs != null) {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    }
  }

  List<int> _inputShape() {
    final input = _manifest.input;
    return input.layout == 'NCHW'
        ? [1, 3, input.height, input.width]
        : [1, input.height, input.width, 3];
  }

  /// Releases the session. Call this when the app closes the model.
  Future<void> close() => _session.close();
}
