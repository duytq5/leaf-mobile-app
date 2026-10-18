import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// The messages of a file, without the `@` metadata.
Map<String, String> _messages(Map<String, dynamic> arb) => {
  for (final entry in arb.entries)
    if (!entry.key.startsWith('@')) entry.key: entry.value as String,
};

Set<String> _placeholders(String message) =>
    RegExp(r'\{([A-Za-z]\w*)')
        .allMatches(message)
        .map((m) => m.group(1)!)
        .toSet()
      ..removeAll(['plural', 'other']);

void main() {
  final english = _messages(_arb('en'));
  final vietnamese = _messages(_arb('vi'));

  test('the Vietnamese file has every English message and no other', () {
    expect(vietnamese.keys.toSet(), english.keys.toSet());
  });

  test('a message keeps the placeholders of its English source', () {
    for (final key in english.keys) {
      expect(
        _placeholders(vietnamese[key]!),
        _placeholders(english[key]!),
        reason: key,
      );
    }
  });

  test('every Vietnamese message is translated', () {
    // The product name is the same in both languages.
    const same = {'appTitle'};
    final untranslated = [
      for (final key in english.keys)
        if (!same.contains(key) && vietnamese[key] == english[key]) key,
    ];

    expect(untranslated, isEmpty);
  });

  test('no message holds a dash', () {
    final dashed = [
      for (final entry in {...english, ...vietnamese}.entries)
        if (RegExp('[—–]').hasMatch(entry.value)) entry.key,
    ];

    expect(dashed, isEmpty);
  });
}
