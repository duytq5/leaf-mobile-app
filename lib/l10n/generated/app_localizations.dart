import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LeafScan'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'Please read and agree to how LeafScan uses your photos.'**
  String get consentIntro;

  /// No description provided for @consentUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos are uploaded'**
  String get consentUploadTitle;

  /// No description provided for @consentUploadBody.
  ///
  /// In en, this message translates to:
  /// **'Every image you take or choose is uploaded to our server.'**
  String get consentUploadBody;

  /// No description provided for @consentTrainTitle.
  ///
  /// In en, this message translates to:
  /// **'Used to train AI'**
  String get consentTrainTitle;

  /// No description provided for @consentTrainBody.
  ///
  /// In en, this message translates to:
  /// **'Images and their labels are used to train and improve the models.'**
  String get consentTrainBody;

  /// No description provided for @consentOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent when you are online'**
  String get consentOnlineTitle;

  /// No description provided for @consentOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'Each photo and its prediction wait on the phone until it is online.'**
  String get consentOnlineBody;

  /// No description provided for @consentReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Read full terms'**
  String get consentReadTerms;

  /// No description provided for @consentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I agree that my images will be uploaded and used for AI training.'**
  String get consentCheckbox;

  /// No description provided for @consentAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree & continue'**
  String get consentAgree;

  /// No description provided for @consentCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get consentCloseApp;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Full terms'**
  String get termsTitle;

  /// No description provided for @termsBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the agreement'**
  String get termsBack;

  /// No description provided for @termsUploadsHeading.
  ///
  /// In en, this message translates to:
  /// **'What the app uploads'**
  String get termsUploadsHeading;

  /// No description provided for @termsUploadsBody.
  ///
  /// In en, this message translates to:
  /// **'The app uploads every photo you take or choose. The app also uploads the prediction of the model and a score that says how certain the model is.'**
  String get termsUploadsBody;

  /// No description provided for @termsWhyHeading.
  ///
  /// In en, this message translates to:
  /// **'Why the app uploads a photo'**
  String get termsWhyHeading;

  /// No description provided for @termsWhyBody.
  ///
  /// In en, this message translates to:
  /// **'The photos build the training set of the next model. A photo from a real field is more useful than a photo from a laboratory.'**
  String get termsWhyBody;

  /// No description provided for @termsWhenHeading.
  ///
  /// In en, this message translates to:
  /// **'When the app sends a photo'**
  String get termsWhenHeading;

  /// No description provided for @termsWhenBody.
  ///
  /// In en, this message translates to:
  /// **'The app keeps each photo and its prediction on the phone. It sends them when you are signed in and the phone is online.'**
  String get termsWhenBody;

  /// No description provided for @termsNotCollectedHeading.
  ///
  /// In en, this message translates to:
  /// **'What the app does not collect'**
  String get termsNotCollectedHeading;

  /// No description provided for @termsNotCollectedBody.
  ///
  /// In en, this message translates to:
  /// **'The app does not ask for your name, your email address or your telephone number. The app does not read your contacts and does not track your position.'**
  String get termsNotCollectedBody;

  /// No description provided for @termsRetentionHeading.
  ///
  /// In en, this message translates to:
  /// **'How long the data stays'**
  String get termsRetentionHeading;

  /// No description provided for @termsRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'The photos stay for the length of the research project. The research team holds them. The team does not sell them and does not give them to an advertiser.'**
  String get termsRetentionBody;

  /// No description provided for @termsStopHeading.
  ///
  /// In en, this message translates to:
  /// **'How to stop'**
  String get termsStopHeading;

  /// No description provided for @termsStopBody.
  ///
  /// In en, this message translates to:
  /// **'Close the app to stop. The app uploads nothing before you agree.'**
  String get termsStopBody;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to LeafScan'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to use the models and send your photos.'**
  String get signInBody;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI model'**
  String get catalogTitle;

  /// No description provided for @catalogIntro.
  ///
  /// In en, this message translates to:
  /// **'Each model recognises a different crop. Check its labels before scanning.'**
  String get catalogIntro;

  /// No description provided for @catalogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String catalogDeleteTitle(String name);

  /// No description provided for @catalogDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The model leaves this phone. You can download it again later.'**
  String get catalogDeleteBody;

  /// No description provided for @catalogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No models yet'**
  String get catalogEmptyTitle;

  /// No description provided for @catalogEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No crop has a released model yet. Check again later.'**
  String get catalogEmptyBody;

  /// No description provided for @catalogUseModel.
  ///
  /// In en, this message translates to:
  /// **'Use {name} model'**
  String catalogUseModel(String name);

  /// No description provided for @catalogChooseModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get catalogChooseModel;

  /// No description provided for @catalogDownloadToStart.
  ///
  /// In en, this message translates to:
  /// **'Download a model to start'**
  String get catalogDownloadToStart;

  /// No description provided for @modelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get modelNotDownloaded;

  /// No description provided for @modelLabelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 label} other{{count} labels}}'**
  String modelLabelCount(int count);

  /// No description provided for @modelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get modelDownloading;

  /// No description provided for @modelDownloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String modelDownloadingPercent(int percent);

  /// No description provided for @modelDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get modelDownload;

  /// No description provided for @modelUpdateTo.
  ///
  /// In en, this message translates to:
  /// **'Update to v{version}'**
  String modelUpdateTo(String version);

  /// No description provided for @captureTitle.
  ///
  /// In en, this message translates to:
  /// **'New scan'**
  String get captureTitle;

  /// No description provided for @captureBack.
  ///
  /// In en, this message translates to:
  /// **'Back to models'**
  String get captureBack;

  /// No description provided for @captureTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get captureTakePhoto;

  /// No description provided for @captureChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get captureChooseFromLibrary;

  /// No description provided for @captureRunning.
  ///
  /// In en, this message translates to:
  /// **'The model is running.'**
  String get captureRunning;

  /// No description provided for @captureHeading.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of one leaf'**
  String get captureHeading;

  /// No description provided for @captureHint.
  ///
  /// In en, this message translates to:
  /// **'Use daylight and a plain background. Let the leaf fill most of the frame.'**
  String get captureHint;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @resultPredictedLabel.
  ///
  /// In en, this message translates to:
  /// **'Predicted label'**
  String get resultPredictedLabel;

  /// No description provided for @resultModelLine.
  ///
  /// In en, this message translates to:
  /// **'{name} model · {version}'**
  String resultModelLine(String name, String version);

  /// No description provided for @resultShowScores.
  ///
  /// In en, this message translates to:
  /// **'Show all scores'**
  String get resultShowScores;

  /// No description provided for @resultHideScores.
  ///
  /// In en, this message translates to:
  /// **'Hide all scores'**
  String get resultHideScores;

  /// No description provided for @resultLatency.
  ///
  /// In en, this message translates to:
  /// **'latency'**
  String get resultLatency;

  /// No description provided for @resultSignInToSend.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send this photo'**
  String get resultSignInToSend;

  /// No description provided for @resultSent.
  ///
  /// In en, this message translates to:
  /// **'Photo sent. Thank you for helping.'**
  String get resultSent;

  /// No description provided for @resultPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo waits} other{{count} photos wait}}. They are sent when the phone is online.'**
  String resultPending(int count);

  /// No description provided for @failureSignInNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not set up in this build.'**
  String get failureSignInNotSetUp;

  /// No description provided for @failureSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was cancelled.'**
  String get failureSignInCancelled;

  /// No description provided for @failureSignInUnfinished.
  ///
  /// In en, this message translates to:
  /// **'The sign-in did not finish. Please try again.'**
  String get failureSignInUnfinished;

  /// No description provided for @failureSignInRefused.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was refused. Please try again.'**
  String get failureSignInRefused;

  /// No description provided for @failureSignInNeeded.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send photos.'**
  String get failureSignInNeeded;

  /// No description provided for @failureSignInExpired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to send photos.'**
  String get failureSignInExpired;

  /// No description provided for @failureCatalogOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Connect to the internet to download a model.'**
  String get failureCatalogOffline;

  /// No description provided for @failureCatalogUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The app cannot read the models. Please try again.'**
  String get failureCatalogUnreadable;

  /// No description provided for @failureModelNotReleased.
  ///
  /// In en, this message translates to:
  /// **'This model is not released.'**
  String get failureModelNotReleased;

  /// No description provided for @failureDownloadDamaged.
  ///
  /// In en, this message translates to:
  /// **'The download was damaged. Please try again.'**
  String get failureDownloadDamaged;

  /// No description provided for @failureDownloadOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. The download did not finish.'**
  String get failureDownloadOffline;

  /// No description provided for @failureDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download failed. Please try again.'**
  String get failureDownloadFailed;

  /// No description provided for @failurePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The photo is larger than 10 MB.'**
  String get failurePhotoTooLarge;

  /// No description provided for @failureImageTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The photo is too small for this model.'**
  String get failureImageTooSmall;

  /// No description provided for @failureQuotaReached.
  ///
  /// In en, this message translates to:
  /// **'You reached today\'s photo limit. The rest are sent later.'**
  String get failureQuotaReached;

  /// No description provided for @failureStorage.
  ///
  /// In en, this message translates to:
  /// **'The phone could not save or read the data. Please try again.'**
  String get failureStorage;

  /// No description provided for @failureModel.
  ///
  /// In en, this message translates to:
  /// **'The model cannot run on this photo.'**
  String get failureModel;

  /// No description provided for @failureImage.
  ///
  /// In en, this message translates to:
  /// **'The app cannot read this photo.'**
  String get failureImage;

  /// No description provided for @failurePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow LeafScan to use the camera and photos in Settings.'**
  String get failurePermission;

  /// No description provided for @failureAuth.
  ///
  /// In en, this message translates to:
  /// **'The sign-in did not work. Please try again.'**
  String get failureAuth;

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please try again when the phone is online.'**
  String get failureNetwork;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
