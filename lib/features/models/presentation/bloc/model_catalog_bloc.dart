import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/catalog_entry.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/usecases/delete_model.dart';
import '../../domain/usecases/download_model.dart';
import '../../domain/usecases/get_catalog.dart';
import '../../domain/usecases/get_selected_id.dart';
import '../../domain/usecases/select_model.dart';

sealed class ModelCatalogEvent extends Equatable {
  const ModelCatalogEvent();

  @override
  List<Object?> get props => [];
}

/// The screen opens, or the user taps "Try again". Read the list and the
/// stored selection.
class ModelsRequested extends ModelCatalogEvent {
  const ModelsRequested();
}

/// The user taps a card. Only a downloaded model can be selected.
class ModelSelected extends ModelCatalogEvent {
  const ModelSelected(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// The user taps "Download" or "Update".
class ModelDownloadRequested extends ModelCatalogEvent {
  const ModelDownloadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// The user confirms "Delete".
class ModelDeleteRequested extends ModelCatalogEvent {
  const ModelDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

enum ModelCatalogStatus { initial, loading, ready, failure }

class ModelCatalogState extends Equatable {
  const ModelCatalogState({
    this.status = ModelCatalogStatus.initial,
    this.entries = const [],
    this.selectedId,
    this.progress = const {},
    this.failure,
  });

  final ModelCatalogStatus status;
  final List<CatalogEntry> entries;
  final String? selectedId;

  /// The models that download now, by id. The value is a fraction from 0 to
  /// 1, or null while the size is unknown.
  final Map<String, double?> progress;

  /// What a snackbar reports. Every new state clears it.
  final Failure? failure;

  /// The selected downloaded model, else the first downloaded one, else null.
  LeafModel? get selected {
    final installed = [
      for (final entry in entries)
        if (entry.installed != null) entry,
    ];
    for (final entry in installed) {
      if (entry.id == selectedId) return entry.installed;
    }
    return installed.isEmpty ? null : installed.first.installed;
  }

  bool isDownloading(String id) => progress.containsKey(id);

  ModelCatalogState copyWith({
    ModelCatalogStatus? status,
    List<CatalogEntry>? entries,
    String? Function()? selectedId,
    Map<String, double?>? progress,
    Failure? failure,
  }) {
    return ModelCatalogState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      progress: progress ?? this.progress,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, entries, selectedId, progress, failure];
}

/// Holds the state of the model list: what the platform released, what is on
/// the phone, the downloads in progress and the selection.
class ModelCatalogBloc extends Bloc<ModelCatalogEvent, ModelCatalogState> {
  ModelCatalogBloc({
    required this.getCatalog,
    required this.getSelectedId,
    required this.selectModel,
    required this.downloadModel,
    required this.deleteModel,
  }) : super(const ModelCatalogState()) {
    on<ModelsRequested>(_onRequested);
    on<ModelSelected>(_onSelected);
    on<ModelDownloadRequested>(_onDownload);
    on<ModelDeleteRequested>(_onDelete);
  }

  final GetCatalog getCatalog;
  final GetSelectedId getSelectedId;
  final SelectModel selectModel;
  final DownloadModel downloadModel;
  final DeleteModel deleteModel;

  Future<void> _onRequested(
    ModelsRequested event,
    Emitter<ModelCatalogState> emit,
  ) async {
    emit(state.copyWith(status: ModelCatalogStatus.loading));

    final entries = await getCatalog(const NoParams());
    if (entries.isLeft()) {
      emit(
        state.copyWith(
          status: ModelCatalogStatus.failure,
          entries: const [],
          failure: entries.getLeft().toNullable(),
        ),
      );
      return;
    }

    final selected = await getSelectedId(const NoParams());
    emit(
      state.copyWith(
        status: ModelCatalogStatus.ready,
        entries: entries.getRight().toNullable(),
        selectedId: () => selected.getRight().toNullable(),
      ),
    );
  }

  Future<void> _onSelected(
    ModelSelected event,
    Emitter<ModelCatalogState> emit,
  ) async {
    if (_entry(event.id)?.installed == null) return;

    // Show the new selection at once. The store is not on the critical path.
    emit(state.copyWith(selectedId: () => event.id));
    final result = await selectModel(event.id);
    if (result.isLeft()) {
      emit(state.copyWith(failure: result.getLeft().toNullable()));
    }
  }

  Future<void> _onDownload(
    ModelDownloadRequested event,
    Emitter<ModelCatalogState> emit,
  ) async {
    final id = event.id;
    if (state.isDownloading(id) || _entry(id) == null) return;

    emit(state.copyWith(progress: {...state.progress, id: null}));
    final result = await downloadModel(
      DownloadModelParams(
        id,
        onProgress: (fraction) {
          if (emit.isDone || !state.isDownloading(id)) return;
          emit(state.copyWith(progress: {...state.progress, id: fraction}));
        },
      ),
    );

    final progress = {...state.progress}..remove(id);
    await result.match(
      (failure) async => emit(
        state.copyWith(progress: progress, failure: failure),
      ),
      (model) async {
        // The first model the user downloads is the one they want to use.
        final select = state.selected == null;
        emit(
          state.copyWith(
            entries: [
              for (final entry in state.entries)
                entry.id == id ? entry.withInstalled(model) : entry,
            ],
            selectedId: select ? () => id : null,
            progress: progress,
          ),
        );
        if (select) await selectModel(id);
      },
    );
  }

  Future<void> _onDelete(
    ModelDeleteRequested event,
    Emitter<ModelCatalogState> emit,
  ) async {
    final id = event.id;
    final result = await deleteModel(id);
    if (result.isLeft()) {
      emit(state.copyWith(failure: result.getLeft().toNullable()));
      return;
    }

    final entries = [
      for (final entry in state.entries)
        if (entry.id != id)
          entry
        // A model the platform no longer lists has nothing left to show.
        else if (entry.releasedVersion != null)
          entry.withInstalled(null),
    ];
    String? selectedId = state.selectedId;
    if (selectedId == id) {
      selectedId = null;
      for (final entry in entries) {
        if (entry.installed != null) {
          selectedId = entry.id;
          break;
        }
      }
      if (selectedId != null) await selectModel(selectedId);
    }
    emit(state.copyWith(entries: entries, selectedId: () => selectedId));
  }

  CatalogEntry? _entry(String id) {
    for (final entry in state.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
