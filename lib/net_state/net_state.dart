import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';

enum NetConnectResult {
  unknown,
  wifi,
  mobile,
  none,
}

class NetState {
  NetState._();

  static NetState? _instance;

  static NetState? get getInstance => _instance;

  static Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static NetConnectResult? _connectResult;
  static Function? tips;

  get netResult {
    return _connectResult;
  }

  set netResult(result) {
    _connectResult = result;
  }

  static Future<void> init(
    Function(ConnectivityResult result) listener, {
    Function(NetConnectResult result)? tips,
  }) async {
    _instance = NetState._();
    NetState.tips = tips;
    ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e);
    }
    // listener(result);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(listener);
  }
}
