import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/features/fincas/domain/finca_repository.dart';
import '../../../models/finca.dart';
import '../../../models/common.dart';
import '../../../services/local_db_service.dart';
import '../../../widgets/sync_indicator.dart';
import 'add_finca_screen.dart';
import '../../../core/logger/app_logger.dart';
import 'finca_detalle_screen.dart';
import 'controller/fincas_controller.dart';
import 'package:tizon_app/shared/widgets/tizon_bottom_nav.dart';

class FincasScreen extends StatefulWidget {
  const FincasScreen({super.key});

  @override
  State<FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<FincasScreen> {
  final FincasController _controller = FincasController();
  List<Finca> _fincas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    logScreen(screenName: 'FincasScreen', fileName: 'fincas_screen.dart');
    _loadFincas();
  }

  // ── Helpers de deserialización desde Firestore ────────────────────────────

  List<LatLng> _parsePoligono(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((p) {
        return LatLng(
          latitude: (p['lat'] as num?)?.toDouble() ?? 0.0,
          longitude: (p['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }
    return [];
  }

  LatLng? _parseUbicacionLegacy(dynamic raw) {
    if (raw is Map) {
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(latitude: lat, longitude: lng);
    }
    // Soporte para el formato anterior que guardaba latitud/longitud separados
    if (raw == null) return null;
    return null;
  }

  // ── Carga de fincas ───────────────────────────────────────────────────────

  Future<void> _loadFincas() async {
    if (_fincas.isEmpty) setState(() => _isLoading = true);
    try {
      final fincasLocales = await _controller.loadFincas();
      setState(() {
        _fincas = fincasLocales;
        if (fincasLocales.isNotEmpty) _isLoading = false;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('fincas')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final fincasLocalesActuales = await _controller.loadFincas();
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final remoteId = doc.id;
            final yaExiste =
                fincasLocalesActuales.any((f) => f.firebaseId == remoteId);
            if (!yaExiste) {
              final poligono = _parsePoligono(data['poligono']);
              final ubicacionLegacy = _parseUbicacionLegacy(data['ubicacion']) ??
                  // Soporte para formato antiguo con latitud/longitud directos
                  (data['latitud'] != null && data['longitud'] != null
                      ? LatLng(
                          latitude: (data['latitud'] as num).toDouble(),
                          longitude: (data['longitud'] as num).toDouble(),
                        )
                      : null);

              final fincaRemota = Finca(
                nombre: data['nombre'] ?? 'Sin nombre',
                poligono: poligono,
                ubicacion: ubicacionLegacy,
                firebaseId: remoteId,
                cultivo: data['cultivo'],
                area: (data['area'] as num?)?.toDouble(),
                imageUrl: data['imageUrl'],
                estadoSinc: EstadoSincronizacion.sincronizada,
                updatedAt: DateTime.now(),
              );
              await _controller.saveFinca(fincaRemota);
            }
          }
          final fincasActualizadas = await _controller.loadFincas();
          if (mounted) setState(() => _fincas = fincasActualizadas);
        }
      }
    } catch (e) {
      debugPrint('❌ Error en _loadFincas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddFinca() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFincaScreen()),
    );
    if (result == true) _loadFincas();
  }

  Future<void> _deleteFinca(Finca finca) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar finca'),
        content: Text('¿Eliminar "${finca.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteFinca(finca.id!);
      _loadFincas();
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
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
                  const Expanded(
                    child: Text('Mis Fincas',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (_fincas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fincas.length} finca${_fincas.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            const SyncIndicator(),

            // Contenido
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF66BB6A)))
                  : RefreshIndicator(
                      onRefresh: _loadFincas,
                      color: const Color(0xFF66BB6A),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildAddButton(),
                            const SizedBox(height: 20),
                            if (_fincas.isEmpty) _buildEmptyState(),
                            ..._fincas.map((finca) => _FincaCard(
                                  finca: finca,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FincaDetalleScreen(finca: finca),
                                    ),
                                  ),
                                  onDelete: () => _deleteFinca(finca),
                                )),
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

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.agriculture_outlined,
                size: 56, color: Colors.green.shade300),
          ),
          const SizedBox(height: 20),
          const Text('Aún no tienes fincas',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Agrega tu primera finca\npara comenzar a registrar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _navigateToAddFinca,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registrar nueva finca',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('Agrega una finca para registrar biocarbón',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de finca ──────────────────────────────────────────────────────────

class _FincaCard extends StatelessWidget {
  final Finca finca;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FincaCard(
      {required this.finca,
      required this.onTap,
      required this.onDelete});

  Color _cultivoColor() {
    switch ((finca.cultivo ?? '').toLowerCase()) {
      case 'cafe':
      case 'café':
        return const Color(0xFF6D4C41);
      case 'aguacate':
        return const Color(0xFF2E7D32);
      case 'cacao':
        return const Color(0xFF4E342E);
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData _cultivoIcon() {
    switch ((finca.cultivo ?? '').toLowerCase()) {
      case 'cafe':
      case 'café':
        return Icons.coffee;
      case 'aguacate':
        return Icons.eco;
      case 'cacao':
        return Icons.spa;
      default:
        return Icons.agriculture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _cultivoColor();
    final sincronizada =
        finca.estadoSinc == EstadoSincronizacion.sincronizada;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono cultivo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_cultivoIcon(), color: color, size: 26),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(finca.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(finca.cultivo ?? 'Sin cultivo',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (finca.area != null) ...[
                          const SizedBox(width: 8),
                          Text('${finca.area?.toStringAsFixed(1)} ha',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                        // Mostrar número de puntos del polígono
                        if (finca.poligono.length > 1) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.pentagon_outlined,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 2),
                          Text('${finca.poligono.length} pts',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          sincronizada
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined,
                          size: 12,
                          color: sincronizada
                              ? Colors.green.shade400
                              : Colors.orange.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sincronizada ? 'Sincronizada' : 'Pendiente sync',
                          style: TextStyle(
                            fontSize: 11,
                            color: sincronizada
                                ? Colors.green.shade400
                                : Colors.orange.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Acciones
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.shade400),
                    onPressed: onTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.redAccent),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
