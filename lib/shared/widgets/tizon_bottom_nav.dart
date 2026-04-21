import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/app/di.dart';

/// Barra de navegación compartida para todas las pantallas.
/// Solo dos opciones: Inicio y Perfil.
class TizonBottomNav extends StatelessWidget {
  final int currentIndex; // 0 = Inicio, 1 = Perfil

  const TizonBottomNav({super.key, this.currentIndex = 0});

  Future<String> _obtenerCedula() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser?.email != null) {
      final email = firebaseUser!.email!;
      if (email.endsWith('@tizon.app')) {
        return email.replaceAll('@tizon.app', '');
      }
      return email;
    }
    final authService = getIt<AuthService>();
    return await authService.getSesionActual() ?? 'Usuario';
  }

  void _showProfileDialog(BuildContext context) async {
    final cedula      = await _obtenerCedula();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mi perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person,
                  size: 36, color: Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cédula: $cedula',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  firebaseUser != null
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  size: 16,
                  color: firebaseUser != null
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  firebaseUser != null
                      ? 'Sincronizado con Firebase'
                      : 'Modo offline',
                  style: TextStyle(
                    fontSize: 13,
                    color: firebaseUser != null
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await getIt<AuthService>().signOut();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Cerrar sesión'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                isActive: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) Navigator.pop(context);
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                isActive: currentIndex == 1,
                onTap: () => _showProfileDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? const Color(0xFF66BB6A)
                    : Colors.grey.shade400,
                size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? const Color(0xFF66BB6A)
                        : Colors.grey.shade400,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
