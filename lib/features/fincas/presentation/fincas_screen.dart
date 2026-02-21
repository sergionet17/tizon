import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/features/fincas/presentation/domain/finca_repository.dart';

// ✅ IMPORTANTE: Eliminamos el import de google_maps_flutter para evitar conflictos
// Importamos directamente tus modelos
import '../../../models/finca.dart';
import '../../../models/common.dart'; // Aquí es donde viven LatLng y EstadoSincronizacion

import '../../../services/local_db_service.dart';
import '../../../widgets/tizon_logo.dart';
import '../../../widgets/sync_indicator.dart';
import 'add_finca_screen.dart';
import '../../../core/logger/app_logger.dart';
import '../../auth/presentation/registro_screen.dart';
import 'controller/fincas_controller.dart';

class FincasScreen extends StatefulWidget {
  const FincasScreen({super.key});

  @override
  State<FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<FincasScreen> {
  final fincas = await _controller.loadFincas();
  List<Finca> _fincas = [];
  bool _isLoading = true;
  final FincasController _controller = FincasController();

  @override
  void initState() {
    super.initState();
    logScreen(screenName: 'FincasScreen', fileName: 'fincas_screen.dart');
    _loadFincas();
  }

  Future<void> _loadFincas() async {
    if (_fincas.isEmpty) setState(() => _isLoading = true);

    try {
      // 1. Carga Local (Hive)
      final fincasLocales = await _fincaRepo.getFincas();
      setState(() {
        _fincas = fincasLocales;
        if (fincasLocales.isNotEmpty) _isLoading = false;
      });

      // 2. Sincronización con Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('fincas')
            .where('userId', isEqualTo: user.uid)
            .get();

// ... dentro de _loadFincas, en la parte de Firebase:

        if (snapshot.docs.isNotEmpty) {
          // 1. Obtenemos las fincas que ya tenemos en local para comparar
          final fincasLocalesActuales = await _fincaRepo.getFincas();

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final remoteId = doc.id;

            // 2. BUSCAMOS SI YA EXISTE:
            // Comprobamos si alguna finca local tiene el mismo firebaseId
            bool yaExiste =
                fincasLocalesActuales.any((f) => f.firebaseId == remoteId);

            if (!yaExiste) {
              final fincaRemota = Finca(
                nombre: data['nombre'] ?? 'Sin nombre',
                ubicacion: LatLng(
                  latitude: (data['latitud'] ?? 0.0).toDouble(),
                  longitude: (data['longitud'] ?? 0.0).toDouble(),
                ),
                firebaseId: remoteId,
                cultivo: data['cultivo'],
                area: (data['area'] as num?)?.toDouble(),
                estadoSinc: EstadoSincronizacion.sincronizada,
                updatedAt: DateTime.now(),
              );

              // Solo guardamos si es realmente nueva
              await _fincaRepo.saveFinca(fincaRemota);
              print("📌 Nueva finca sincronizada: ${fincaRemota.nombre}");
            } else {
              print(
                  "⏩ Finca saltada (ya existe localmente): ${data['nombre']}");
            }
          }

          // 3. RE-CARGAMOS DESDE HIVE (ya sin duplicados)
          final fincasActualizadas = await _fincaRepo.getFincas();
          if (mounted) {
            setState(() => _fincas = fincasActualizadas);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error en _loadFincas: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- El resto de los métodos se mantienen igual ---

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
        title: const Text('Eliminar finca'),
        content:
            Text('¿Estás seguro de que deseas eliminar "${finca.nombre}"?'),
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
      await _fincaRepo.deleteFinca(finca.id! as String);
      _loadFincas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tizón SAS',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  TizonLogo(
                      size: 40, showText: false, color: Colors.grey.shade700),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mis Fincas',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (_fincas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('${_fincas.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SyncIndicator(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF66BB6A)))
                  : RefreshIndicator(
                      onRefresh: _loadFincas,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            if (_fincas.isNotEmpty)
                              ..._fincas.map((finca) => _FincaCard(
                                    finca: finca,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                RegistroScreen(finca: finca))),
                                    onDelete: () => _deleteFinca(finca),
                                  )),
                            if (_fincas.isEmpty) _buildEmptyState(),
                            const SizedBox(height: 20),
                            _buildAddButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.agriculture_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('¡Aún no tienes fincas!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _navigateToAddFinca,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66BB6A),
            foregroundColor: Colors.white),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Nueva Finca'),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: const Color(0xFF66BB6A),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
            icon: Icon(Icons.assignment), label: 'Registro'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}

// --- Cards auxiliares ---

class _FincaCard extends StatelessWidget {
  final Finca finca;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FincaCard(
      {required this.finca, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(Icons.agriculture, color: Colors.green.shade700),
        ),
        title: Text(finca.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(finca.cultivo ?? 'Sin cultivo'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
