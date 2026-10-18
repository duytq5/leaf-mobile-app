import '../../l10n/generated/app_localizations.dart';
import '../error/failures.dart';

extension FailureText on AppLocalizations {
  /// The sentence a screen shows for [failure]. The English message of the
  /// failure is for a developer and never reaches the screen.
  String failure(Failure failure) {
    final code = failure.code;
    if (code != null) return _coded(code);
    return switch (failure) {
      QuotaFailure() => failureQuotaReached,
      NetworkFailure() => failureNetwork,
      AuthFailure() => failureAuth,
      PermissionFailure() => failurePermission,
      ImageFailure() => failureImage,
      ModelFailure() => failureModel,
      _ => failureStorage,
    };
  }

  String _coded(FailureCode code) => switch (code) {
    FailureCode.signInNotSetUp => failureSignInNotSetUp,
    FailureCode.signInCancelled => failureSignInCancelled,
    FailureCode.signInUnfinished => failureSignInUnfinished,
    FailureCode.signInRefused => failureSignInRefused,
    FailureCode.signInNeeded => failureSignInNeeded,
    FailureCode.signInExpired => failureSignInExpired,
    FailureCode.catalogOffline => failureCatalogOffline,
    FailureCode.catalogUnreadable => failureCatalogUnreadable,
    FailureCode.modelNotReleased => failureModelNotReleased,
    FailureCode.downloadDamaged => failureDownloadDamaged,
    FailureCode.downloadOffline => failureDownloadOffline,
    FailureCode.downloadFailed => failureDownloadFailed,
    FailureCode.photoTooLarge => failurePhotoTooLarge,
  };
}
