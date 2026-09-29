import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/usecases/get_models.dart';
import '../../domain/usecases/get_selected_model.dart';
import '../../domain/usecases/select_model.dart';

sealed class ModelCatalogEvent extends Equatable {
  const ModelCatalogEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opens. Read the catalog and the stored selection.
class ModelsRequested extends ModelCatalogEvent {
  const ModelsRequested();
}

/// The user taps a card.
class ModelSelected extends ModelCatalogEvent {
  const ModelSelected(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

enum ModelCatalogStatus { initial, loading, ready, failure }

class ModelCatalogState extends Equatable {
  const ModelCatalogState({
    this.status = ModelCatalogStatus.initial,
    this.models = const [],
    this.selectedId,
    this.message,
  });

  final ModelCatalogStatus status;
  final List<LeafModel> models;
  final String? selectedId;
  final String? message;

  /// The model the user selected, or null while the list is empty.
  LeafModel? get selected {
    for (final model in models) {
      if (model.id == selectedId) return model;
    }
    return models.isEmpty ? null : models.first;
  }

  ModelCatalogState copyWith({
    ModelCatalogStatus? status,
    List<LeafModel>? models,
    String? selectedId,
    String? message,
  }) {
    return ModelCatalogState(
      status: status ?? this.status,
      models: models ?? this.models,
      selectedId: selectedId ?? this.selectedId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, models, selectedId, message];
}

/// Holds the state of the model picker.
class ModelCatalogBloc extends Bloc<ModelCatalogEvent, ModelCatalogState> {
  ModelCatalogBloc({
    required this.getModels,
    required this.getSelectedModel,
    required this.selectModel,
  }) : super(const ModelCatalogState()) {
    on<ModelsRequested>(_onRequested);
    on<ModelSelected>(_onSelected);
  }

  final GetModels getModels;
  final GetSelectedModel getSelectedModel;
  final SelectModel selectModel;

  Future<void> _onRequested(
    ModelsRequested event,
    Emitter<ModelCatalogState> emit,
  ) async {
    emit(state.copyWith(status: ModelCatalogStatus.loading));

    final models = await getModels(const NoParams());
    if (models.isLeft()) {
      emit(
        state.copyWith(
          status: ModelCatalogStatus.failure,
          message: models.getLeft().toNullable()!.message,
        ),
      );
      return;
    }

    final selected = await getSelectedModel(const NoParams());
    emit(
      state.copyWith(
        status: ModelCatalogStatus.ready,
        models: models.getRight().toNullable(),
        selectedId: selected.getRight().toNullable()?.id,
      ),
    );
  }

  Future<void> _onSelected(
    ModelSelected event,
    Emitter<ModelCatalogState> emit,
  ) async {
    // Show the new selection at once. The store is not on the critical path.
    emit(state.copyWith(selectedId: event.id));

    final result = await selectModel(event.id);
    if (result.isLeft()) {
      emit(
        state.copyWith(
          status: ModelCatalogStatus.failure,
          message: result.getLeft().toNullable()!.message,
        ),
      );
    }
  }
}
