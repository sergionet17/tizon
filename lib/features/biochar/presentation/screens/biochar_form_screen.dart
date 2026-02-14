import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/biochar_batch.dart';
import '../../../../features/biochar/presentation/controller/biochar_form_controller.dart';

class BiocharFormScreen extends StatefulWidget {
  final int fincaId; // local id de la finca seleccionada
  const BiocharFormScreen({super.key, required this.fincaId});

  @override
  State<BiocharFormScreen> createState() => _BiocharFormScreenState();
}

class _BiocharFormScreenState extends State<BiocharFormScreen> {
  late final BiocharFormController controller;

  final _humedadCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = BiocharFormController(fincaId: widget.fincaId);
    controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    // opcional: sincroniza text controllers con estado si lo necesitas
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    _humedadCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  void _showPickDialog(
      {required VoidCallback camera, required VoidCallback gallery}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  camera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  gallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.state;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Producir Biocarbón'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '* = campos requeridos',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 12),

            // Tipo Biomasa *
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tipo Biomasa*',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TipoBiomasa>(
                    value: s.tipoBiomasa,
                    items: const [
                      DropdownMenuItem(
                          value: TipoBiomasa.maderaSocaCafe,
                          child: Text('Madera de soca de café')),
                      DropdownMenuItem(
                          value: TipoBiomasa.pulpaCafe,
                          child: Text('Pulpa de café')),
                      DropdownMenuItem(
                          value: TipoBiomasa.otro, child: Text('Otro')),
                    ],
                    onChanged:
                        s.loading ? null : (v) => controller.setTipoBiomasa(v!),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Imagen Biomasa *
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Imagen Biomasa*',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: s.loading
                        ? null
                        : () => _showPickDialog(
                              camera: () => controller
                                  .pickBiomasaImage(ImageSource.camera),
                              gallery: () => controller
                                  .pickBiomasaImage(ImageSource.gallery),
                            ),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: s.biomasaImage == null
                          ? const Center(
                              child: Icon(Icons.camera_alt, size: 40))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  _AdaptiveXImage(path: s.biomasaImage!.path),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Imágenes humedad
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Imágenes de humedad',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (s.humedadImages.isEmpty)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child:
                          const Center(child: Icon(Icons.camera_alt, size: 36)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < s.humedadImages.length; i++)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: _AdaptiveXImage(
                                      path: s.humedadImages[i].path),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: s.loading
                                      ? null
                                      : () => controller.removeHumedadAt(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: s.loading
                        ? null
                        : () => _showPickDialog(
                              camera: () => controller
                                  .addHumedadImage(ImageSource.camera),
                              gallery: () => controller
                                  .addHumedadImage(ImageSource.gallery),
                            ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar otra imagen de humedad'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Humedad material entrada (0-100)
            _Card(
              child: TextField(
                controller: _humedadCtrl,
                keyboardType: TextInputType.number,
                onChanged: controller.setHumedadEntrada,
                decoration: const InputDecoration(
                  labelText: 'Humedad material de entrada (0-100)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Temperatura quema *
            _Card(
              child: TextField(
                controller: _tempCtrl,
                keyboardType: TextInputType.number,
                onChanged: controller.setTemperatura,
                decoration: const InputDecoration(
                  labelText: 'Temperatura de quema*',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    Text(s.error!, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: s.loading
                    ? null
                    : () async {
                        final id = await controller.submit();
                        if (!mounted) return;
                        if (id != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Guardado. Se sincroniza cuando haya internet.')),
                          );
                          Navigator.pop(context, true);
                        }
                      },
                child: s.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _AdaptiveXImage extends StatelessWidget {
  final String path;
  const _AdaptiveXImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // image_picker web devuelve blob url utilizable con Image.network
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)));
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }
}
