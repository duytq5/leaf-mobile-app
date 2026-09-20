import 'package:flutter/material.dart';

/// The first screen of the app.
///
/// The screen holds the capture actions. The classifier is not connected yet.
/// See `docs/superpowers/specs/2026-09-20-mobile-cv-app-design.md`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaf Disease')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'No model is loaded.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
