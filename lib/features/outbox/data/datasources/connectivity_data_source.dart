import 'package:connectivity_plus/connectivity_plus.dart';

/// Tells when the phone gets a network again.
abstract class ConnectivityDataSource {
  Stream<void> get onlineAgain;
}

class ConnectivityDataSourceImpl implements ConnectivityDataSource {
  ConnectivityDataSourceImpl([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<void> get onlineAgain => _connectivity.onConnectivityChanged.where(
    (kinds) => kinds.any((kind) => kind != ConnectivityResult.none),
  );
}
