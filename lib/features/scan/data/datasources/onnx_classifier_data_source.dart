import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../../../models/domain/entities/leaf_model.dart';
import 'preprocessor.dart';

/// Runs an ONNX model and returns the raw output.
abstract class OnnxClassifierDataSource {
  /// Returns the logits of the model for one image.
  Future<List<double>> run({
    required Uint8List bytes,
    required LeafModel model,
  });

  Future<void> close();
}

class OnnxClassifierDataSourceImpl implements OnnxClassifierDataSource {
  OnnxClassifierDataSourceImpl([OnnxRuntime? runtime])
    : _runtime = runtime ?? OnnxRuntime();

  final OnnxRuntime _runtime;

  /// One session for each model id and version. A session creation costs
  /// hundreds of milliseconds, so the map keeps the session for the next scan.
  final Map<String, OrtSession> _sessions = {};

  @override
  Future<List<double>> run({
    required Uint8List bytes,
    required LeafModel model,
  }) async {
    final session = await _sessionFor(model);
    final tensor = Preprocessor(model.manifest.input).run(bytes);
    final input = await OrtValue.fromList(tensor, _shapeOf(model));

    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({session.inputNames.first: input});
      final output = outputs[session.outputNames.first];
      if (output == null) {
        throw StateError('the model returns no output');
      }
      final raw = await output.asFlattenedList();
      return raw.map((value) => (value as num).toDouble()).toList();
    } finally {
      await input.dispose();
      if (outputs != null) {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    }
  }

  Future<OrtSession> _sessionFor(LeafModel model) async {
    final key = '${model.id}@${model.version}';
    final open = _sessions[key];
    if (open != null) return open;

    // The CPU gives a repeatable latency on a low performance device. Add
    // CORE_ML or NNAPI only after a measurement shows a benefit.
    final options = OrtSessionOptions(providers: [OrtProvider.CPU]);
    final session = await _runtime.createSession(
      model.modelFile,
      options: options,
    );
    _sessions[key] = session;
    return session;
  }

  List<int> _shapeOf(LeafModel model) {
    final input = model.manifest.input;
    return input.layout == 'NCHW'
        ? [1, 3, input.height, input.width]
        : [1, input.height, input.width, 3];
  }

  @override
  Future<void> close() async {
    for (final session in _sessions.values) {
      await session.close();
    }
    _sessions.clear();
  }
}
