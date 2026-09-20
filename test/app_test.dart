import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/src/app.dart';

void main() {
  testWidgets('the app starts and shows the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LeafDiseaseApp()));

    expect(find.text('Leaf Disease'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
