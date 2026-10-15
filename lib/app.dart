import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/consent/presentation/bloc/consent_bloc.dart';
import 'features/consent/presentation/pages/consent_page.dart';
import 'features/models/domain/entities/leaf_model.dart';
import 'features/models/presentation/bloc/model_catalog_bloc.dart';
import 'features/models/presentation/pages/model_catalog_page.dart';
import 'features/outbox/presentation/bloc/outbox_bloc.dart';
import 'features/scan/domain/entities/scan_result.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';
import 'features/scan/presentation/pages/capture_page.dart';
import 'features/scan/presentation/pages/result_page.dart';
import 'injection_container.dart';

/// The root widget of the app.
class LeafScanApp extends StatelessWidget {
  const LeafScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The outbox lives as long as the app, so a scan is sent even after the
    // user leaves the result screen.
    return BlocProvider(
      lazy: false,
      create: (_) => sl<OutboxBloc>()..add(const OutboxStarted()),
      child: MaterialApp(
        title: 'LeafScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const ConsentGate(),
      ),
    );
  }
}

/// The first screen of the flow.
///
/// The gate reads the stored agreement. An agreed record opens the picker at
/// once. A clear record shows the agreement screen.
class ConsentGate extends StatelessWidget {
  const ConsentGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConsentBloc>()..add(const ConsentRequested()),
      child: Builder(
        builder: (context) {
          return BlocBuilder<ConsentBloc, ConsentState>(
            builder: (context, state) {
              return switch (state.status) {
                ConsentStatus.initial ||
                ConsentStatus.loading => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                ConsentStatus.accepted => const ModelCatalogRoute(),
                _ => ConsentPage(
                  onAccepted: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ModelCatalogRoute(),
                    ),
                  ),
                ),
              };
            },
          );
        },
      ),
    );
  }
}

/// Artboard 1, with its bloc.
class ModelCatalogRoute extends StatelessWidget {
  const ModelCatalogRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ModelCatalogBloc>()..add(const ModelsRequested()),
      child: Builder(
        builder: (context) => ModelCatalogPage(
          onContinue: (model) => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => CaptureRoute(model: model)),
          ),
        ),
      ),
    );
  }
}

/// Artboard 2, with its bloc.
class CaptureRoute extends StatelessWidget {
  const CaptureRoute({required this.model, super.key});

  final LeafModel model;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ScanBloc>(),
      child: Builder(
        builder: (context) => CapturePage(
          model: model,
          onBack: () => Navigator.of(context).pop(),
          onResult: (result) {
            context.read<OutboxBloc>().add(
              OutboxScanQueued(result: result, model: model),
            );
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ResultRoute(result: result, model: model),
              ),
            );
            // The capture screen returns to rest, so the user can scan again
            // after the result screen closes.
            context.read<ScanBloc>().add(const ScanCleared());
          },
        ),
      ),
    );
  }
}

/// Artboard 3.
class ResultRoute extends StatelessWidget {
  const ResultRoute({required this.result, required this.model, super.key});

  final ScanResult result;
  final LeafModel model;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OutboxBloc, OutboxState>(
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) => ResultPage(
        result: result,
        model: model,
        signedIn: state.signedIn,
        pending: state.pending,
        onSignIn: () =>
            context.read<OutboxBloc>().add(const OutboxSignInRequested()),
        onBack: () => Navigator.of(context).pop(),
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }
}
