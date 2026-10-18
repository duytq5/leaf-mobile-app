import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  /// The words of the screen in the phone's language.
  ///
  /// A widget built outside the app's [Localizations], such as in a test,
  /// reads the English words.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
