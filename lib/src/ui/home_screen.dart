import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/classifier.dart';
import '../model/model_loader.dart';
import '../model/prediction.dart';
import '../model/preprocessor.dart';

/// The only screen of stage 1.
///
/// The user selects an image. The app runs the model. The app shows the
/// classes and the confidence.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Classifier? _classifier;
  String? _loadError;
  Uint8List? _imageBytes;
  Prediction? _prediction;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _classifier?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      final classifier = await loadBundledClassifier();
      if (!mounted) {
        await classifier.close();
        return;
      }
      setState(() => _classifier = classifier);
    } on ClassifierException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    }
  }

  Future<void> _pickAndClassify(ImageSource source) async {
    final classifier = _classifier;
    if (classifier == null || _busy) return;

    final XFile? file;
    try {
      file = await _picker.pickImage(source: source);
    } catch (error) {
      setState(() => _error = 'the picker failed: $error');
      return;
    }
    if (file == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _prediction = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final prediction = await classifier.classify(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _prediction = prediction;
      });
    } on PreprocessException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ClassifierException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaf Disease')),
      body: SafeArea(child: _body()),
      bottomNavigationBar: _actions(),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return _message(
        icon: Icons.error_outline,
        title: 'The model does not load.',
        detail: '$_loadError\n\n'
            'Run tools/export_onnx.py to produce assets/models/model.onnx.',
      );
    }
    if (_classifier == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_imageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (_busy) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        if (_prediction != null) ..._results(_prediction!),
        if (_imageBytes == null && !_busy && _error == null)
          const Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(child: Text('Select an image to run the model.')),
          ),
      ],
    );
  }

  List<Widget> _results(Prediction prediction) {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 16),
      Text(prediction.top.label, style: theme.textTheme.headlineSmall),
      Text(
        '${(prediction.top.probability * 100).toStringAsFixed(1)}% confidence',
        style: theme.textTheme.bodyMedium,
      ),
      const Divider(height: 32),
      for (final score in prediction.scores)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(score.label)),
              Text('${(score.probability * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      const Divider(height: 32),
      // These numbers belong in the thesis report.
      Text('latency: ${prediction.latency.inMilliseconds} ms',
          style: theme.textTheme.bodySmall),
      Text('entropy: ${prediction.uncertainty.entropy.toStringAsFixed(4)}',
          style: theme.textTheme.bodySmall),
      Text('margin: ${prediction.uncertainty.margin.toStringAsFixed(4)}',
          style: theme.textTheme.bodySmall),
      Text('model: ${prediction.modelVersion}',
          style: theme.textTheme.bodySmall),
    ];
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final enabled = _classifier != null && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: enabled
                  ? () => _pickAndClassify(ImageSource.gallery)
                  : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Library'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled
                  ? () => _pickAndClassify(ImageSource.camera)
                  : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
          ),
        ],
      ),
    );
  }
}
