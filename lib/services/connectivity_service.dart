import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

void _updateConnectionStatus(List<ConnectivityResult> results) {
  final wasOnline = _isOnline;
  _isOnline = results.any((r) => r != ConnectivityResult.none);

  // ✅ LOGS CLAROS
  if (!wasOnline && _isOnline) {
    print('✅ [CONNECTIVITY] Internet detectado. Se reanudan operaciones.');
  } else if (wasOnline && !_isOnline) {
    print('❌ [CONNECTIVITY] Conexión perdida. Modo offline activado.');
  }

  _controller.add(_isOnline);
}
  void dispose() {
    _controller.close();
  }
}