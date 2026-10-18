import 'package:flutter/material.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/l10n/generated/app_localizations.dart';

/// A [MaterialApp] with the app's translations, for a screen in one language.
Widget localizedApp(Widget home, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
