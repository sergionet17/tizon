import 'dart:async';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _controller = StreamController<bool>.broadcast();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  Stream<bool> get onSyncChanged => _controller.stream;

void startSync() {
  print('🔄 [SYNC] Iniciando sincronización de usuarios offline...');
  _isSyncing = true;
  _controller.add(true);
}

void endSync() {
  print('✅ [SYNC] Sincronización completada.');
  _isSyncing = false;
  _controller.add(false);
}
}