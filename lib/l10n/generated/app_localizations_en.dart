// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LeafScan';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get tryAgain => 'Try again';

  @override
  String get continueAction => 'Continue';

  @override
  String get consentTitle => 'Before you start';

  @override
  String get consentIntro =>
      'Please read and agree to how LeafScan uses your photos.';

  @override
  String get consentUploadTitle => 'Photos are uploaded';

  @override
  String get consentUploadBody =>
      'Every image you take or choose is uploaded to our server.';

  @override
  String get consentTrainTitle => 'Used to train AI';

  @override
  String get consentTrainBody =>
      'Images and their labels are used to train and improve the models.';

  @override
  String get consentOnlineTitle => 'Sent when you are online';

  @override
  String get consentOnlineBody =>
      'Each photo and its prediction wait on the phone until it is online.';

  @override
  String get consentReadTerms => 'Read full terms';

  @override
  String get consentCheckbox =>
      'I agree that my images will be uploaded and used for AI training.';

  @override
  String get consentAgree => 'Agree & continue';

  @override
  String get consentCloseApp => 'Close app';

  @override
  String get termsTitle => 'Full terms';

  @override
  String get termsBack => 'Back to the agreement';

  @override
  String get termsUploadsHeading => 'What the app uploads';

  @override
  String get termsUploadsBody =>
      'The app uploads every photo you take or choose. The app also uploads the prediction of the model and a score that says how certain the model is.';

  @override
  String get termsWhyHeading => 'Why the app uploads a photo';

  @override
  String get termsWhyBody =>
      'The photos build the training set of the next model. A photo from a real field is more useful than a photo from a laboratory.';

  @override
  String get termsWhenHeading => 'When the app sends a photo';

  @override
  String get termsWhenBody =>
      'The app keeps each photo and its prediction on the phone. It sends them when you are signed in and the phone is online.';

  @override
  String get termsNotCollectedHeading => 'What the app does not collect';

  @override
  String get termsNotCollectedBody =>
      'The app does not ask for your name, your email address or your telephone number. The app does not read your contacts and does not track your position.';

  @override
  String get termsRetentionHeading => 'How long the data stays';

  @override
  String get termsRetentionBody =>
      'The photos stay for the length of the research project. The research team holds them. The team does not sell them and does not give them to an advertiser.';

  @override
  String get termsStopHeading => 'How to stop';

  @override
  String get termsStopBody =>
      'Close the app to stop. The app uploads nothing before you agree.';

  @override
  String get signInTitle => 'Sign in to LeafScan';

  @override
  String get signInBody =>
      'Sign in with your Google account to use the models and send your photos.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get catalogTitle => 'Choose an AI model';

  @override
  String get catalogIntro =>
      'Each model recognises a different crop. Check its labels before scanning.';

  @override
  String catalogDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get catalogDeleteBody =>
      'The model leaves this phone. You can download it again later.';

  @override
  String get catalogEmptyTitle => 'No models yet';

  @override
  String get catalogEmptyBody =>
      'No crop has a released model yet. Check again later.';

  @override
  String catalogUseModel(String name) {
    return 'Use $name model';
  }

  @override
  String get catalogChooseModel => 'Choose a model';

  @override
  String get catalogDownloadToStart => 'Download a model to start';

  @override
  String get modelNotDownloaded => 'Not downloaded';

  @override
  String modelLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labels',
      one: '1 label',
    );
    return '$_temp0';
  }

  @override
  String get modelDownloading => 'Downloading…';

  @override
  String modelDownloadingPercent(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get modelDownload => 'Download';

  @override
  String modelUpdateTo(String version) {
    return 'Update to v$version';
  }

  @override
  String get captureTitle => 'New scan';

  @override
  String get captureBack => 'Back to models';

  @override
  String get captureTakePhoto => 'Take photo';

  @override
  String get captureChooseFromLibrary => 'Choose from library';

  @override
  String get captureRunning => 'The model is running.';

  @override
  String get captureHeading => 'Add a photo of one leaf';

  @override
  String get captureHint =>
      'Use daylight and a plain background. Let the leaf fill most of the frame.';

  @override
  String get resultTitle => 'Result';

  @override
  String get resultPredictedLabel => 'Predicted label';

  @override
  String resultModelLine(String name, String version) {
    return '$name model · $version';
  }

  @override
  String get resultShowScores => 'Show all scores';

  @override
  String get resultHideScores => 'Hide all scores';

  @override
  String get resultLatency => 'latency';

  @override
  String get resultSignInToSend => 'Sign in to send this photo';

  @override
  String get resultSent => 'Photo sent. Thank you for helping.';

  @override
  String resultPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos wait',
      one: '1 photo waits',
    );
    return '$_temp0. They are sent when the phone is online.';
  }

  @override
  String get failureSignInNotSetUp => 'Sign-in is not set up in this build.';

  @override
  String get failureSignInCancelled => 'The sign-in was cancelled.';

  @override
  String get failureSignInUnfinished =>
      'The sign-in did not finish. Please try again.';

  @override
  String get failureSignInRefused =>
      'The sign-in was refused. Please try again.';

  @override
  String get failureSignInNeeded => 'Sign in to send photos.';

  @override
  String get failureSignInExpired => 'Sign in again to send photos.';

  @override
  String get failureCatalogOffline =>
      'No connection. Connect to the internet to download a model.';

  @override
  String get failureCatalogUnreadable =>
      'The app cannot read the models. Please try again.';

  @override
  String get failureModelNotReleased => 'This model is not released.';

  @override
  String get failureDownloadDamaged =>
      'The download was damaged. Please try again.';

  @override
  String get failureDownloadOffline =>
      'No connection. The download did not finish.';

  @override
  String get failureDownloadFailed => 'The download failed. Please try again.';

  @override
  String get failurePhotoTooLarge => 'The photo is larger than 10 MB.';

  @override
  String get failureImageTooSmall => 'The photo is too small for this model.';

  @override
  String get failureQuotaReached =>
      'You reached today\'s photo limit. The rest are sent later.';

  @override
  String get failureStorage =>
      'The phone could not save or read the data. Please try again.';

  @override
  String get failureModel => 'The model cannot run on this photo.';

  @override
  String get failureImage => 'The app cannot read this photo.';

  @override
  String get failurePermission =>
      'Allow LeafScan to use the camera and photos in Settings.';

  @override
  String get failureAuth => 'The sign-in did not work. Please try again.';

  @override
  String get failureNetwork =>
      'No connection. Please try again when the phone is online.';
}
