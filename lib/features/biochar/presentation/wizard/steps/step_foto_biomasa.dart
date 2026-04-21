import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

class StepFotoBiomasa extends WizardStep {
  const StepFotoBiomasa({
    super.key,
    required super.controller,
    required super.onNext,
    required super.onBack,
  });

  @override
  String get titulo => 'Foto de la biomasa';

  @override
  bool get puedeAvanzar => controller.state.biomasaImage != null;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return WizardStepBase(
      icono: Icons.camera_alt_outlined,
      iconoColor: const Color(0xFF1565C0),
      titulo: titulo,
      descripcion: 'Toma una foto del material antes de carbonizarlo.',
      puedeAvanzar: puedeAvanzar,
      onNext: onNext,
      contenido: Column(
        children: [
          GestureDetector(
            onTap: () => _mostrarOpciones(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: s.biomasaImage != null
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade300,
                  width: s.biomasaImage != null ? 2 : 1,
                ),
              ),
              child: s.biomasaImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Toca para tomar la foto',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('Cámara o galería',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: kIsWeb
                              ? Image.network(s.biomasaImage!.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity)
                              : Image.file(File(s.biomasaImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: GestureDetector(
                            onTap: () => _mostrarOpciones(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Foto lista',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
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
                  controller.pickBiomasaImage(ImageSource.camera);
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
                  controller.pickBiomasaImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
