import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

/// The root widget of the app.
class LeafScanApp extends StatelessWidget {
  const LeafScanApp({required this.home, super.key});

  /// The first screen. The injection container decides which one it is.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeafScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home,
    );
  }
}
