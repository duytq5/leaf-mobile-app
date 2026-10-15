import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Opens the managed login page in the system browser and waits for the
/// redirect back to the app. The app never sees the password.
abstract class BrowserAuthDataSource {
  /// Returns the redirect URL. Throws when the user closes the browser.
  Future<Uri> authenticate(Uri url, String callbackScheme);
}

class BrowserAuthDataSourceImpl implements BrowserAuthDataSource {
  @override
  Future<Uri> authenticate(Uri url, String callbackScheme) async => Uri.parse(
    await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
    ),
  );
}
