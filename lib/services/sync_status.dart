import 'package:flutter/foundation.dart';

enum SyncState {
  offline,     // no hay internet
  idleOnline,  // hay internet pero no está sincronizando
  syncing,     // sincronizando
  error,       // error
}

class SyncStatus {
  static final ValueNotifier<SyncState> state =
      ValueNotifier<SyncState>(SyncState.idleOnline);

  static final ValueNotifier<String?> message =
      ValueNotifier<String?>(null);

  static void set(SyncState s, {String? msg}) {
    state.value = s;
    message.value = msg;
  }
}