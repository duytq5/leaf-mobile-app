import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../entities/image_source_kind.dart';
import '../entities/label_correction.dart';
import '../entities/scan_result.dart';

abstract class ScanRepository {
  /// Returns the bytes of the selected image.
  ///
  /// A cancelled picker returns an [ImageFailure].
  Future<Either<Failure, Uint8List>> pickImage(ImageSourceKind source);

  Future<Either<Failure, ScanResult>> classify({
    required Uint8List bytes,
    required LeafModel model,
  });

  /// Stores a correction on the device. Stage 3 uploads the file.
  Future<Either<Failure, Unit>> saveCorrection(LabelCorrection correction);
}
