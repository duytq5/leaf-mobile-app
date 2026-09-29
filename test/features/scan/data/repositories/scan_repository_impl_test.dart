import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/scan/data/datasources/correction_local_data_source.dart';
import 'package:leaf_disease_mobile/features/scan/data/datasources/image_picker_data_source.dart';
import 'package:leaf_disease_mobile/features/scan/data/datasources/onnx_classifier_data_source.dart';
import 'package:leaf_disease_mobile/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/image_source_kind.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/label_correction.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';

class MockPicker extends Mock implements ImagePickerDataSource {}

class MockClassifier extends Mock implements OnnxClassifierDataSource {}

class MockCorrections extends Mock implements CorrectionLocalDataSource {}

final imageBytes = Uint8List.fromList(List.filled(32, 7));

void main() {
  late MockPicker picker;
  late MockClassifier classifier;
  late MockCorrections corrections;
  late ScanRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(ImageSourceKind.camera);
    registerFallbackValue(coffeeModel);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      LabelCorrection(
        modelId: 'x',
        modelVersion: 'v',
        predictedLabel: 'a',
        correctedLabel: 'b',
        submittedAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    picker = MockPicker();
    classifier = MockClassifier();
    corrections = MockCorrections();
    repository = ScanRepositoryImpl(
      picker: picker,
      classifier: classifier,
      corrections: corrections,
    );
  });

  group('pickImage', () {
    test('returns the bytes of the selected image', () async {
      when(() => picker.pick(any())).thenAnswer((_) async => imageBytes);

      final result = await repository.pickImage(ImageSourceKind.gallery);

      expect(result.getRight().toNullable(), imageBytes);
      verify(() => picker.pick(ImageSourceKind.gallery)).called(1);
    });

    test('a cancelled picker is an ImageFailure', () async {
      when(() => picker.pick(any())).thenAnswer((_) async => null);

      final result = await repository.pickImage(ImageSourceKind.camera);

      expect(result.getLeft().toNullable(), isA<ImageFailure>());
    });

    test('an exception becomes an ImageFailure', () async {
      when(() => picker.pick(any())).thenThrow(Exception('denied'));

      final result = await repository.pickImage(ImageSourceKind.camera);

      expect(result.getLeft().toNullable(), isA<ImageFailure>());
    });
  });

  group('classify', () {
    Future<void> givenLogits(List<double> logits) async {
      when(() => classifier.run(bytes: any(named: 'bytes'), model: any(named: 'model')))
          .thenAnswer((_) async => logits);
    }

    test('sorts the scores with the highest probability first', () async {
      // The order of the labels is healthy, red spider mite, rust.
      await givenLogits([0.1, 3.0, 1.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);
      final scan = result.getRight().toNullable()!;

      expect(scan.scores.map((s) => s.label), [
        'coffee___red_spider_mite',
        'coffee___rust',
        'coffee___healthy',
      ]);
      expect(scan.top.label, 'coffee___red_spider_mite');
    });

    test('keeps every label paired with its own logit', () async {
      await givenLogits([9.0, 1.0, 2.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);

      expect(result.getRight().toNullable()!.top.label, 'coffee___healthy');
    });

    test('produces probabilities that sum to one', () async {
      await givenLogits([2.0, -1.0, 0.5]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);
      final total = result
          .getRight()
          .toNullable()!
          .scores
          .map((s) => s.probability)
          .reduce((a, b) => a + b);

      expect(total, closeTo(1.0, 1e-12));
    });

    test('computes the uncertainty from the same distribution', () async {
      await givenLogits([1.0, 1.0, 1.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);
      final scan = result.getRight().toNullable()!;

      expect(scan.uncertainty.margin, closeTo(0.0, 1e-9));
      expect(scan.uncertainty.entropy, greaterThan(1.0));
    });

    test('carries the model id and the version', () async {
      await givenLogits([1.0, 0.0, 0.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);
      final scan = result.getRight().toNullable()!;

      expect(scan.modelId, 'coffee_rocole');
      expect(scan.modelVersion, 'fold-1-best');
    });

    test('a logit count that differs from the labels is a ModelFailure',
        () async {
      // This is the failure a wrong manifest causes. It must not reach the user
      // as a wrong label.
      await givenLogits([1.0, 2.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);

      expect(result.getLeft().toNullable(), isA<ModelFailure>());
      expect(
        result.getLeft().toNullable()!.message,
        contains('2 values but the manifest lists 3 labels'),
      );
    });

    test('works for a model with six labels', () async {
      await givenLogits([0.0, 0.0, 0.0, 5.0, 0.0, 0.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: durianModel);
      final scan = result.getRight().toNullable()!;

      expect(scan.scores, hasLength(6));
      expect(scan.top.label, 'Leaf_Healthy');
    });

    test('an exception from the runtime is a ModelFailure', () async {
      when(() => classifier.run(bytes: any(named: 'bytes'), model: any(named: 'model')))
          .thenThrow(Exception('session closed'));

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);

      expect(result.getLeft().toNullable(), isA<ModelFailure>());
    });

    test('returns an unmodifiable score list', () async {
      await givenLogits([1.0, 2.0, 3.0]);

      final result =
          await repository.classify(bytes: imageBytes, model: coffeeModel);

      expect(
        () => result.getRight().toNullable()!.scores.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('saveCorrection', () {
    final correction = LabelCorrection(
      modelId: 'coffee_rocole',
      modelVersion: 'fold-1-best',
      predictedLabel: 'coffee___rust',
      correctedLabel: 'coffee___healthy',
      submittedAt: DateTime(2026, 9, 29),
    );

    test('appends the correction', () async {
      when(() => corrections.append(any())).thenAnswer((_) async {});

      final result = await repository.saveCorrection(correction);

      expect(result.isRight(), isTrue);
      verify(() => corrections.append(correction)).called(1);
    });

    test('an exception becomes a CacheFailure', () async {
      when(() => corrections.append(any())).thenThrow(Exception('full'));

      final result = await repository.saveCorrection(correction);

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('writes the fields the server reads', () {
      expect(correction.toJson(), {
        'model_id': 'coffee_rocole',
        'model_version': 'fold-1-best',
        'predicted_label': 'coffee___rust',
        'corrected_label': 'coffee___healthy',
        'submitted_at': DateTime(2026, 9, 29).toIso8601String(),
      });
    });
  });
}
