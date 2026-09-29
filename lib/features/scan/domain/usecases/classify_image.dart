import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../entities/scan_result.dart';
import '../repositories/scan_repository.dart';

class ClassifyParams extends Equatable {
  const ClassifyParams({required this.bytes, required this.model});

  final Uint8List bytes;
  final LeafModel model;

  @override
  List<Object?> get props => [bytes, model];
}

/// Runs the model on one image.
class ClassifyImage extends UseCase<ScanResult, ClassifyParams> {
  ClassifyImage(this.repository);

  final ScanRepository repository;

  @override
  Future<Either<Failure, ScanResult>> call(ClassifyParams params) =>
      repository.classify(bytes: params.bytes, model: params.model);
}
