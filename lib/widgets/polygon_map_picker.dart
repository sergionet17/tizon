import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/common.dart';

/// Pantalla completa para definir el polígono de una finca sobre mapa satelital.
///
/// El usuario mueve el mapa debajo de la cruceta fija y toca "Agregar punto"
/// para ir marcando los vértices del terreno. Al terminar se calcula el área
/// en hectáreas usando la fórmula del exceso esférico.
class PolygonMapPicker extends StatefulWidget {
  final List<LatLng> initialPoints;
  final void Function(List<LatLng> points, double areaHa) onFinish;
  final VoidCallback onCancel;

  const PolygonMapPicker({
    super.key,
    this.initialPoints = const [],
    required this.onFinish,
    required this.onCancel,
  });

  @override
  State<PolygonMapPicker> createState() => _PolygonMapPickerState();
}

class _PolygonMapPickerState extends State<PolygonMapPicker> {
  final MapController _mapController = MapController();
  final List<LatLng> _points = [];
  ll.LatLng _initialCenter = const ll.LatLng(1.853, -76.050); // Pitalito fallback
  bool _loadingGps = false;
  bool _mapReady = false;

  // Colores del tema
  static const _colorRojo = Color(0xFFFF5722);
  static const _colorVerde = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _points.addAll(widget.initialPoints);
    _initLocation();
  }

  // ── Conversión entre nuestro LatLng y el de flutter_map ──────────────────

  ll.LatLng _toLl(LatLng p) => ll.LatLng(p.latitude, p.longitude);
  LatLng _fromLl(ll.LatLng p) => LatLng(latitude: p.latitude, longitude: p.longitude);

  // ── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    final pos = await _getPosition();
    if (pos != null) {
      final target = ll.LatLng(pos.latitude, pos.longitude);
      setState(() => _initialCenter = target);
      if (_mapReady) _mapController.move(target, 17);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      final pos = await _getPosition();
      if (pos != null) {
        _mapController.move(ll.LatLng(pos.latitude, pos.longitude), 17);
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<Position?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Acciones del polígono ─────────────────────────────────────────────────

  void _addPoint() {
    if (!_mapReady) return;
    final center = _mapController.camera.center;
    setState(() {
      _points.add(LatLng(latitude: center.latitude, longitude: center.longitude));
    });
  }

  void _undo() {
    if (_points.isNotEmpty) setState(() => _points.removeLast());
  }

  void _finish() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos 3 puntos para definir el polígono'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onFinish(_points, _calcAreaHa(_points));
  }

  // ── Cálculo de área (fórmula del exceso esférico) ─────────────────────────

  double _calcAreaHa(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    double area = 0;
    const r = 6371000.0; // radio terrestre en metros
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      final lat1 = pts[i].latitude * math.pi / 180;
      final lat2 = pts[j].latitude * math.pi / 180;
      final dLon = (pts[j].longitude - pts[i].longitude) * math.pi / 180;
      area += dLon * (2 + math.sin(lat1) + math.sin(lat2));
    }
    return (area * r * r / 2).abs() / 10000; // m² → ha
  }

  // ── Coordenadas del centro del mapa ──────────────────────────────────────

  String get _centerText {
    if (!_mapReady) return '';
    try {
      final c = _mapController.camera.center;
      return '${c.latitude.toStringAsFixed(6)}°N, '
          '${c.longitude.toStringAsFixed(6)}°E';
    } catch (_) {
      return '';
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final llPoints = _points.map(_toLl).toList();
    final areaHa = _calcAreaHa(_points);

    return Scaffold(
      body: Stack(
        children: [
          // ── MAPA SATELITAL ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15,
              onMapReady: () => setState(() => _mapReady = true),
              onPositionChanged: (_, __) {
                if (mounted) setState(() {});
              },
            ),
            children: [
              // Tiles satelitales de Esri (gratuito, sin API key)
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/'
                    'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.tizon.app',
              ),

              // Relleno del polígono (solo con ≥3 puntos)
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: llPoints,
                      color: _colorRojo.withOpacity(0.22),
                      borderColor: _colorRojo,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

              // Líneas entre puntos (con 2+ puntos)
              if (_points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: llPoints,
                      color: _colorRojo,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),

              // Marcadores numerados
              MarkerLayer(
                markers: _points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final isFirst = idx == 0;
                  return Marker(
                    point: _toLl(entry.value),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isFirst ? _colorVerde : _colorRojo,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── CRUCETA CENTRAL ─────────────────────────────────────────────
          const Center(child: _Crosshair()),

          // ── COORDENADAS (esquina inferior izquierda) ────────────────────
          Positioned(
            left: 12,
            bottom: 108,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _centerText,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),

          // ── BOTÓN GPS (esquina inferior derecha) ─────────────────────────
          Positioned(
            right: 16,
            bottom: 112,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              elevation: 3,
              onPressed: _loadingGps ? null : _goToCurrentLocation,
              child: _loadingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1976D2),
                      ),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF1976D2)),
            ),
          ),

          // ── PANEL INFERIOR ───────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black87,
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _points.isEmpty
                        ? 'Mueve el mapa y toca "Agregar punto"'
                        : '${_points.length} punto(s)'
                            '${areaHa > 0 ? '  ·  ${areaHa.toStringAsFixed(2)} ha' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Cancelar
                      Expanded(
                        child: _BottomBtn(
                          label: 'Cancelar',
                          color: Colors.grey.shade700,
                          onPressed: widget.onCancel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Deshacer
                      Expanded(
                        child: _BottomBtn(
                          label: 'Deshacer',
                          color: Colors.orange,
                          onPressed: _points.isEmpty ? null : _undo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Agregar punto
                      Expanded(
                        flex: 2,
                        child: _BottomBtn(
                          label: 'Agregar punto',
                          color: _colorRojo,
                          onPressed: _addPoint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Listo
                      Expanded(
                        child: _BottomBtn(
                          label: 'Listo',
                          color: _colorVerde,
                          onPressed: _points.length >= 3 ? _finish : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── BOTÓN ATRÁS (esquina superior izquierda) ─────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onCancel,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cruceta ──────────────────────────────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final shadow = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Sombra
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), shadow);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), shadow);
    canvas.drawCircle(Offset(cx, cy), 5, shadow);

    // Blanco
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), white);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), white);
    canvas.drawCircle(Offset(cx, cy), 5, white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Botón del panel inferior ─────────────────────────────────────────────────

class _BottomBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _BottomBtn({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
