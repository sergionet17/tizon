import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tizon_app/services/local_db_service.dart';
import 'package:tizon_app/services/local_image_service.dart';

import '../../../models/finca.dart';
import '../../../models/common.dart';
import '../../../widgets/polygon_map_picker.dart';

class AddFincaScreen extends StatefulWidget {
  const AddFincaScreen({super.key});

  @override
  State<AddFincaScreen> createState() => _AddFincaScreenState();
}

class _AddFincaScreenState extends State<AddFincaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cultivoController = TextEditingController();
  final _areaController = TextEditingController();

  final _dbService = LocalDbService();
  final _imageService = LocalImageService();
  final _picker = ImagePicker();

  XFile? _imageFile;
  bool _isLoading = false;

  // ── Polígono ──────────────────────────────────────────────────────────────
  List<LatLng> _poligono = [];
  double _areaHa = 0;

  @override
  void dispose() {
    _nombreController.dispose();
    _cultivoController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // ── Mapa ──────────────────────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PolygonMapPicker(
          initialPoints: _poligono,
          onFinish: (points, areaHa) {
            setState(() {
              _poligono = points;
              _areaHa = areaHa;
              // Auto-rellenar el campo de área
              _areaController.text = areaHa.toStringAsFixed(2);
            });
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // ── Imagen ────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF66BB6A)),
                ),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF66BB6A),
                  ),
                ),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    // Validar polígono antes del form
    if (_poligono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes definir la ubicación de la finca en el mapa'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final areaFinal = _areaController.text.trim().isEmpty
          ? (_areaHa > 0 ? _areaHa : null)
          : double.tryParse(_areaController.text.trim());

      final nuevaFinca = Finca(
        nombre: _nombreController.text.trim(),
        poligono: _poligono,
        cultivo: _cultivoController.text.trim().isEmpty
            ? null
            : _cultivoController.text.trim(),
        area: areaFinal,
        estadoSinc: EstadoSincronizacion.pendiente,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final fincaId = await _dbService.saveFinca(nuevaFinca);

      if (_imageFile != null && !kIsWeb) {
        final imagePath = await _imageService.saveImage(
          File(_imageFile!.path),
          fincaId.toString(),
        );
        final fincaActualizada = nuevaFinca.copyWith(
          id: fincaId,
          imagePath: imagePath,
        );
        await _dbService.saveFinca(fincaActualizada);
      } else if (_imageFile != null && kIsWeb) {
        print(
          '🌐 [AddFinca] Imagen seleccionada en Web: no se guarda como archivo local.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Finca registrada exitosamente!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registrar Nueva Finca',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto ──────────────────────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _showImageSourceDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb
                                  ? Image.network(
                                      _imageFile!.path,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_imageFile!.path),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _imageFile = null),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(opcional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Nombre ────────────────────────────────────────────────────
              TextFormField(
                controller: _nombreController,
                enabled: !_isLoading,
                decoration: _inputDecoration(
                  label: 'Nombre de la finca *',
                  icon: Icons.agriculture,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Ubicación (botón que abre el mapa) ────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _openMapPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: _poligono.isEmpty
                        ? null
                        : Border.all(
                            color: const Color(0xFF66BB6A),
                            width: 2,
                          ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: _poligono.isEmpty
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFF43A047),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _poligono.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ubicación de la finca *',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Toca para abrir el mapa y trazar el terreno',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ubicación definida ✓',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_poligono.length} puntos  ·  '
                                    '${_areaHa.toStringAsFixed(2)} ha  '
                                    '(toca para editar)',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Icon(
                        _poligono.isEmpty
                            ? Icons.arrow_forward_ios
                            : Icons.check_circle,
                        color: _poligono.isEmpty
                            ? Colors.grey.shade400
                            : const Color(0xFF66BB6A),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Cultivo ───────────────────────────────────────────────────
              TextFormField(
                controller: _cultivoController,
                enabled: !_isLoading,
                decoration: _inputDecoration(
                  label: 'Tipo de cultivo',
                  hint: 'Ej: Café, Plátano, Cacao...',
                  icon: Icons.local_florist,
                ),
              ),

              const SizedBox(height: 16),

              // ── Área ──────────────────────────────────────────────────────
              TextFormField(
                controller: _areaController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Área en hectáreas',
                  hint: _areaHa > 0
                      ? 'Calculada automáticamente: ${_areaHa.toStringAsFixed(2)} ha'
                      : 'Ej: 5.5',
                  icon: Icons.square_foot,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) return 'Ingresa un número válido';
                    if (parsed <= 0) return 'El área debe ser mayor a 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ── Guardar ───────────────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Finca',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF66BB6A)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
