import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../domain/entities/class_score.dart';
import '../../domain/entities/image_source_kind.dart';
import '../../domain/entities/label_correction.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/entities/uncertainty.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/correction_local_data_source.dart';
import '../datasources/image_picker_data_source.dart';
import '../datasources/onnx_classifier_data_source.dart';
import '../datasources/preprocessor.dart';

class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({
    required this.picker,
    required this.classifier,
    required this.corrections,
  });

  final ImagePickerDataSource picker;
  final OnnxClassifierDataSource classifier;
  final CorrectionLocalDataSource corrections;

  @override
  Future<Either<Failure, Uint8List>> pickImage(ImageSourceKind source) async {
    try {
      final bytes = await picker.pick(source);
      if (bytes == null) {
        return const Left(ImageFailure('the user selected no image'));
      }
      return Right(bytes);
    } catch (error) {
      return Left(ImageFailure('the picker does not answer: $error'));
    }
  }

  @override
  Future<Either<Failure, ScanResult>> classify({
    required Uint8List bytes,
    required LeafModel model,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final logits = await classifier.run(bytes: bytes, model: model);

      if (logits.length != model.labels.length) {
        return Left(
          ModelFailure(
            'the model returns ${logits.length} values but the manifest lists '
            '${model.labels.length} labels',
          ),
        );
      }

      final probabilities = softmax(logits);
      final scores = <ClassScore>[
        for (var i = 0; i < model.labels.length; i++)
          ClassScore(
            model.labelNames[i],
            probabilities[i],
            code: model.labels[i],
          ),
      ]..sort((a, b) => b.probability.compareTo(a.probability));
      stopwatch.stop();

      return Right(
        ScanResult(
          imageBytes: bytes,
          scores: List.unmodifiable(scores),
          uncertainty: Uncertainty.fromProbabilities(probabilities),
          latency: stopwatch.elapsed,
          modelId: model.id,
          modelVersion: model.version,
        ),
      );
    } on PreprocessException catch (error) {
      return Left(ImageFailure(error.message));
    } catch (error) {
      return Left(ModelFailure('the model does not run: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveCorrection(
    LabelCorrection correction,
  ) async {
    try {
      await corrections.append(correction);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot store the correction: $error'));
    }
  }
}
