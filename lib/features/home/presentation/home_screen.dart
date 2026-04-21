import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tizon_app/features/fincas/presentation/fincas_screen.dart';
import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/services/connectivity_service.dart';
import 'package:tizon_app/widgets/tizon_logo.dart';
import 'package:tizon_app/widgets/connectivity_indicator.dart';
import 'package:tizon_app/shared/widgets/tizon_bottom_nav.dart';
import 'package:tizon_app/app/di.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String> _obtenerCedula() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser?.email != null) {
      final email = firebaseUser!.email!;
      if (email.endsWith('@tizon.app')) return email.replaceAll('@tizon.app', '');
      return email;
    }
    return await getIt<AuthService>().getSesionActual() ?? 'Usuario';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFE8F5E9),
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      FutureBuilder<String>(
                        future: _obtenerCedula(),
                        builder: (context, snap) {
                          final cedula = snap.data ?? '...';
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  TizonLogo(size: 32, showText: false, color: Colors.grey.shade700),
                                  const SizedBox(width: 8),
                                  const Text('Tizón SAS',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.person_outline, size: 13, color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(cedula,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                            color: Colors.green.shade800)),
                                  ]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Card principal — Comenzar a registrar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const FincasScreen())),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B5E20).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20, top: -20,
                                  child: Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 30, bottom: -30,
                                  child: Container(
                                    width: 100, height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.camera_alt_outlined,
                                            color: Colors.white, size: 32),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text('Comenzar a\nregistrar',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.2,
                                          )),
                                      const SizedBox(height: 8),
                                      Text('Registra tu producción\nde biocarbón',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.8),
                                            height: 1.4,
                                          )),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Text('Ir a mis fincas',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
                                              )),
                                          const SizedBox(width: 6),
                                          Icon(Icons.arrow_forward,
                                              size: 16, color: Colors.green.shade800),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Cards secundarias
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SecondaryCard(
                                icon: Icons.bar_chart_outlined,
                                title: 'Dashboard',
                                subtitle: 'Ver estadísticas',
                                color: const Color(0xFF1565C0),
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SecondaryCard(
                                icon: Icons.search,
                                title: 'Mis fincas',
                                subtitle: 'Ver registros',
                                color: const Color(0xFF6A1B9A),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const FincasScreen())),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Banner info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.eco, color: Colors.green.shade700, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Biocarbón certificado',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Cada registro genera un bono de carbono trazable',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: TizonBottomNav(currentIndex: 0),
            ),
            ConnectivityIndicator(isOnline: isOnline),
          ],
        );
      },
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
