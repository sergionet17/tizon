import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tizon_app/models/finca.dart';
import 'package:tizon_app/models/biochar_batch.dart';
import 'package:tizon_app/models/common.dart';
import 'package:tizon_app/services/biochar_local_db_service.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'package:tizon_app/shared/widgets/tizon_bottom_nav.dart';

class FincaDetalleScreen extends StatefulWidget {
  final Finca finca;
  const FincaDetalleScreen({super.key, required this.finca});

  @override
  State<FincaDetalleScreen> createState() => _FincaDetalleScreenState();
}

class _FincaDetalleScreenState extends State<FincaDetalleScreen> {
  final _db = BiocharLocalDbService();
  List<BiocharBatch> _batches = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarBatches();
  }

  Future<void> _cargarBatches() async {
    if (widget.finca.id == null) {
      setState(() => _cargando = false);
      return;
    }
    final lista = await _db.getBatchesByFinca(widget.finca.id!);
    setState(() {
      _batches = lista;
      _cargando = false;
    });
  }

  Color _cultivoColor() {
    switch ((widget.finca.cultivo ?? '').toLowerCase()) {
      case 'cafe': case 'café': return const Color(0xFF6D4C41);
      case 'aguacate': return const Color(0xFF2E7D32);
      case 'cacao': return const Color(0xFF4E342E);
      default: return const Color(0xFF1565C0);
    }
  }

  String _labelEstado(EstadoSincronizacion s) {
    switch (s) {
      case EstadoSincronizacion.sincronizada: return 'Sincronizado';
      case EstadoSincronizacion.pendiente:    return 'Pendiente';
      default: return 'Pendiente';
    }
  }

  Color _colorEstado(EstadoSincronizacion s) {
    return s == EstadoSincronizacion.sincronizada
        ? Colors.green.shade600
        : Colors.orange.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final finca = widget.finca;
    final color = _cultivoColor();

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header con foto de finca
            _buildHeader(finca, color),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info de la finca
                    _buildInfoFinca(finca, color),
                    const SizedBox(height: 20),

                    // Botón principal — Registrar producción
                    _buildBotonProduccion(),
                    const SizedBox(height: 24),

                    // Historial de registros
                    _buildHistorial(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TizonBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader(Finca finca, Color color) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Imagen o banner de color
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                ),
                child: finca.imagePath != null && !kIsWeb
                    ? Image.file(
                        File(finca.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImagen(color),
                      )
                    : finca.imageUrl != null
                        ? Image.network(
                            finca.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImagen(color),
                          )
                        : _placeholderImagen(color),
              ),
              // Botón regreso
              Positioned(
                top: 12, left: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                ),
              ),
            ],
          ),
          // Nombre de la finca
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(finca.nombre,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      if (finca.cultivo != null)
                        Text(finca.cultivo!,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_batches.length} registro${_batches.length != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImagen(Color color) {
    return Center(
      child: Icon(Icons.agriculture_outlined,
          size: 64, color: color.withOpacity(0.4)),
    );
  }

  Widget _buildInfoFinca(Finca finca, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (finca.area != null) ...[
            _InfoChip(
              icon: Icons.square_foot,
              label: '${finca.area!.toStringAsFixed(1)} ha',
              color: color,
            ),
            const SizedBox(width: 12),
          ],
          _InfoChip(
            icon: Icons.location_on_outlined,
            label: finca.ubicacionTexto,
            color: Colors.grey.shade600,
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonProduccion() {
    return GestureDetector(
      onTap: () async {
        if (widget.finca.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: finca sin ID local')),
          );
          return;
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BiocharWizard(fincaId: widget.finca.id!),
          ),
        );
        if (result == true) _cargarBatches();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registrar producción',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Tomar fotos del proceso de biocarbón',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
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

  Widget _buildHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial de registros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_cargando)
          const Center(
              child: CircularProgressIndicator(color: Color(0xFF66BB6A)))
        else if (_batches.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Sin registros aún',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Registra tu primera producción\nde biocarbón',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400)),
              ],
            ),
          )
        else
          ..._batches.map((b) => _BatchCard(batch: b)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool small;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: small ? 13 : 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: small ? 11 : 13,
                color: color,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  final BiocharBatch batch;
  const _BatchCard({required this.batch});

  String _tipoBiomasaLabel(TipoBiomasa t) {
    switch (t) {
      case TipoBiomasa.maderaSocaCafe: return 'Madera soca café';
      case TipoBiomasa.pulpaCafe:      return 'Pulpa de café';
      case TipoBiomasa.otro:           return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = batch.createdAt != null
        ? '${batch.createdAt!.day}/${batch.createdAt!.month}/${batch.createdAt!.year}'
        : 'Sin fecha';

    final sinc = batch.estadoSinc == EstadoSincronizacion.sincronizada;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department,
                color: Color(0xFF1B5E20), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tipoBiomasaLabel(batch.tipoBiomasa),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${batch.temperaturaQuema}°C · $fecha',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sinc
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sinc ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                  size: 12,
                  color: sinc ? Colors.green.shade600 : Colors.orange.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  sinc ? 'Sync' : 'Pendiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sinc
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}