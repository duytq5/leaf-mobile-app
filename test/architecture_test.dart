import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads every Dart file under `lib/` and returns the ones a rule rejects.
List<String> _offenders(bool Function(String path, String source) rejects) {
  final found = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (rejects(entity.path, entity.readAsStringSync())) found.add(entity.path);
  }
  return found..sort();
}

void main() {
  test('no domain file imports Flutter', () {
    final offenders = _offenders(
      (path, source) =>
          path.contains('/domain/') && source.contains('package:flutter/'),
    );

    expect(offenders, isEmpty,
        reason: 'the domain layer must hold no Flutter type');
  });

  test('no domain file imports a package of the data layer', () {
    const dataOnly = [
      'package:flutter_onnxruntime/',
      'package:image_picker/',
      'package:shared_preferences/',
      'package:image/',
      'package:dio/',
    ];

    final offenders = _offenders(
      (path, source) =>
          path.contains('/domain/') && dataOnly.any(source.contains),
    );

    expect(offenders, isEmpty,
        reason: 'the domain layer must not know which package stores the data');
  });

  test('no domain file imports the data layer', () {
    final offenders = _offenders(
      (path, source) =>
          path.contains('/domain/') &&
          (source.contains("/data/") || source.contains("data/datasources")),
    );

    expect(offenders, isEmpty,
        reason: 'the domain layer sits below the data layer');
  });

  test('a bloc uses a use case, never a data source', () {
    final offenders = _offenders(
      (path, source) =>
          path.endsWith('_bloc.dart') && source.contains('data/datasources'),
    );

    expect(offenders, isEmpty);
  });

  test('a page holds no colour of its own', () {
    final offenders = _offenders(
      (path, source) =>
          path.contains('/presentation/') &&
          RegExp(r'Color\(0x').hasMatch(source),
    );

    expect(offenders, isEmpty,
        reason: 'a screen reads a colour from AppColors');
  });
}
