import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/leafscan_mark.dart';
import '../../../../core/widgets/primary_button.dart';

/// The screen after the agreement. The models open only for a signed-in user,
/// and Google is the only way in.
class SignInPage extends StatelessWidget {
  const SignInPage({required this.busy, required this.onSignIn, super.key});

  /// The sign-in browser is open, so the button waits.
  final bool busy;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const LeafScanTile(),
              const SizedBox(height: 12),
              Text(
                'Sign in to LeafScan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your Google account to use the models and send '
                'your photos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Sign in with Google',
                icon: Icons.login,
                onPressed: busy ? null : onSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
