import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
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
    final l10n = context.l10n;
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
                l10n.signInTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.signInWithGoogle,
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
