import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

class StepFotosHumedad extends WizardStep {
  const StepFotosHumedad({
    super.key,
    required super.controller,
    required super.onNext,
    required super.onBack,
  });

  @override
  String get titulo => 'Fotos de humedad';

  @override
  bool get puedeAvanzar => true; // opcional — siempre puede avanzar

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return WizardStepBase(
      icono: Icons.water_drop_outlined,
      iconoColor: const Color(0xFF1565C0),
      titulo: titulo,
      descripcion: 'Opcional: toma fotos que muestren la humedad del material.',
      puedeAvanzar: puedeAvanzar,
      onNext: onNext,
      labelBoton: s.humedadImages.isEmpty ? 'Omitir' : 'Siguiente',
      contenido: Column(
        children: [
          // Grid de fotos
          if (s.humedadImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: s.humedadImages.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(s.humedadImages[i].path,
                            fit: BoxFit.cover)
                        : Image.file(File(s.humedadImages[i].path),
                            fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => controller.removeHumedadAt(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón agregar foto
          GestureDetector(
            onTap: () => _mostrarOpciones(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.blue.shade200,
                    style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: Colors.blue.shade600, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    s.humedadImages.isEmpty
                        ? 'Agregar foto de humedad'
                        : 'Agregar otra foto',
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          if (s.humedadImages.isEmpty) ...[
            const SizedBox(height: 12),
            Text('Este paso es opcional. Puedes omitirlo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
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
                width: 40, height: 4,
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.green.shade700),
                ),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  controller.addHumedadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue.shade700),
                ),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  controller.addHumedadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
