import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final bool isSyncing;

  const SyncIndicator({super.key, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    if (!isSyncing) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 50, right: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: const Text(
            'Sincronizando…',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }
}