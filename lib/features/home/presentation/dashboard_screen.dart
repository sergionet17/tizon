import 'package:flutter/material.dart';
import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/core/logger/app_logger.dart';
import 'package:tizon_app/services/local_db_service.dart';
import 'package:tizon_app/services/biochar_local_db_service.dart';
import 'package:tizon_app/models/common.dart';
import 'package:tizon_app/shared/widgets/tizon_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _cargando = true;
  int _totalFincas = 0;
  int _totalRegistros = 0;
  int _pendientesSync = 0;
  int _sincronizados = 0;

  @override
  void initState() {
    super.initState();
    logScreen(screenName: 'DashboardScreen', fileName: 'dashboard_screen.dart');
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    try {
      final db = getIt<LocalDbService>();
      final biocharDb = BiocharLocalDbService();

      final fincas = await db.getFincas();
      final pendientesFincas = await db.getFincasPendientesSinc();

      // Contar registros de biocarbón de todas las fincas
      int totalBatches = 0;
      int syncBatches = 0;
      for (final f in fincas) {
        if (f.id != null) {
          final batches = await biocharDb.getBatchesByFinca(f.id!);
          totalBatches += batches.length;
          syncBatches += batches
              .where((b) => b.estadoSinc == EstadoSincronizacion.sincronizada)
              .length;
        }
      }

      final sincFincas = fincas
          .where((f) => f.estadoSinc == EstadoSincronizacion.sincronizada)
          .length;

      setState(() {
        _totalFincas = fincas.length;
        _totalRegistros = totalBatches;
        _pendientesSync = pendientesFincas.length + (totalBatches - syncBatches);
        _sincronizados = sincFincas + syncBatches;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Dashboard',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text('Resumen de tu actividad',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF66BB6A)))
                  : RefreshIndicator(
                      onRefresh: _cargarStats,
                      color: const Color(0xFF66BB6A),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grid de stats principales
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                              children: [
                                _StatCard(
                                  valor: '$_totalFincas',
                                  label: 'Fincas\nregistradas',
                                  icono: Icons.agriculture_outlined,
                                  color: const Color(0xFF2E7D32),
                                ),
                                _StatCard(
                                  valor: '$_totalRegistros',
                                  label: 'Registros de\nbiocarbón',
                                  icono: Icons.local_fire_department_outlined,
                                  color: const Color(0xFFE65100),
                                ),
                                _StatCard(
                                  valor: '$_sincronizados',
                                  label: 'Elementos\nsincronizados',
                                  icono: Icons.cloud_done_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                                _StatCard(
                                  valor: '$_pendientesSync',
                                  label: 'Pendientes\nde sync',
                                  icono: Icons.cloud_upload_outlined,
                                  color: _pendientesSync > 0
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFF2E7D32),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Banner de progreso
                            if (_totalRegistros > 0) ...[
                              const Text('Progreso de sincronización',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Registros sincronizados',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600)),
                                        Text(
                                          '$_sincronizados / ${_sincronizados + _pendientesSync}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (_sincronizados +
                                                    _pendientesSync) ==
                                                0
                                            ? 0
                                            : _sincronizados /
                                                (_sincronizados +
                                                    _pendientesSync),
                                        minHeight: 10,
                                        backgroundColor:
                                            Colors.grey.shade100,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Color(0xFF2E7D32)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Info card si no hay datos
                            if (_totalFincas == 0)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.bar_chart_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    const Text('Aún no hay datos',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Registra tu primera finca y producción\npara ver estadísticas aquí.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),

                            // Info bono carbono
                            if (_totalRegistros > 0) ...[
                              const Text('Impacto estimado',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1B5E20),
                                      Color(0xFF388E3C)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.eco,
                                          color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_totalRegistros bono${_totalRegistros != 1 ? 's' : ''} generado${_totalRegistros != 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                              'Cada registro contribuye al\ncertificado de carbono trazable',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TizonBottomNav(currentIndex: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String label;
  final IconData icono;
  final Color color;

  const _StatCard({
    required this.valor,
    required this.label,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}
