import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/image_source_kind.dart';
import '../repositories/scan_repository.dart';

/// Asks the user for a photo.
class PickImage extends UseCase<Uint8List, ImageSourceKind> {
  PickImage(this.repository);

  final ScanRepository repository;

  @override
  Future<Either<Failure, Uint8List>> call(ImageSourceKind params) =>
      repository.pickImage(params);
}
