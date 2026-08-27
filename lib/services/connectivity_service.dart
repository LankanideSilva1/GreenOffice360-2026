import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Returns the current network connection types.
  Future<List<ConnectivityResult>> get connectionType async {
    return await _connectivity.checkConnectivity();
  }

  /// Returns true if a network interface is available.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();

    return !results.contains(ConnectivityResult.none);
  }

  /// Checks whether the device can actually reach the internet.
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(
        const Duration(seconds: 3),
      );

      return result.isNotEmpty &&
          result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Stream that emits true when a network connection exists
  /// and false when the device is disconnected.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) {
        return !results.contains(
          ConnectivityResult.none,
        );
      },
    );
  }

  /// Stream of the actual connectivity types.
  Stream<List<ConnectivityResult>>
      get onConnectionTypeChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Returns a human-readable connection name.
  Future<String> get connectionName async {
    final results = await connectionType;

    if (results.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    }

    if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    }

    if (results.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    }

    if (results.contains(ConnectivityResult.bluetooth)) {
      return 'Bluetooth';
    }

    return 'No Connection';
  }
}