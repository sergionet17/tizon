import 'package:flutter/material.dart';
import '../services/sync_status.dart';

class SyncBanner extends StatelessWidget {
  final EdgeInsets margin;
  const SyncBanner({super.key, this.margin = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncStatus.state,
      builder: (context, state, _) {
        final msg = SyncStatus.message.value;

        String text;
        IconData icon;
        Color bg;

        switch (state) {
          case SyncState.offline:
            text = 'Sin internet • No sincronizando';
            icon = Icons.wifi_off;
            bg = Colors.orange.shade700;
            break;
          case SyncState.idleOnline:
            text = 'Internet OK • Sincronización en espera';
            icon = Icons.wifi;
            bg = Colors.blueGrey.shade700;
            break;
          case SyncState.syncing:
            text = 'Sincronizando…';
            icon = Icons.sync;
            bg = Colors.green.shade700;
            break;
          case SyncState.error:
            text = 'Error de sincronización';
            icon = Icons.error_outline;
            bg = Colors.red.shade700;
            break;
        }

        final extra = (msg != null && msg.isNotEmpty) ? ' • $msg' : '';
        final finalText = '$text$extra';

        return Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  finalText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state == SyncState.syncing) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
