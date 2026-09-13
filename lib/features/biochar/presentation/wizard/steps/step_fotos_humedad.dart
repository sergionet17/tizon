import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

const _kMinFotos = 5;

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
  bool get puedeAvanzar =>
      controller.state.humedadImages.length >= _kMinFotos;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final count = s.humedadImages.length;
    final faltantes = (_kMinFotos - count).clamp(0, _kMinFotos);
    final completo = count >= _kMinFotos;

    return WizardStepBase(
      icono: Icons.water_drop_outlined,
      iconoColor: const Color(0xFF1565C0),
      titulo: titulo,
      descripcion:
          'Toma $_kMinFotos fotos que muestren la humedad del material (obligatorio).',
      puedeAvanzar: puedeAvanzar,
      onNext: onNext,
      labelBoton:
          completo ? 'Siguiente' : 'Faltan $faltantes foto${faltantes == 1 ? '' : 's'}',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Progreso ────────────────────────────────────────────
          _ProgresoFotos(count: count, minimo: _kMinFotos),
          const SizedBox(height: 16),

          // ─── Grid de fotos ───────────────────────────────────────
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
                    top: 4,
                    right: 4,
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

          // ─── Botón agregar foto ──────────────────────────────────
          GestureDetector(
            onTap: () => _mostrarOpciones(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: completo
                      ? Colors.green.shade300
                      : Colors.blue.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: completo
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    count == 0
                        ? 'Agregar foto de humedad'
                        : 'Agregar otra foto',
                    style: TextStyle(
                      color: completo
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!completo && count == 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 6),
                Text(
                  'Se requieren al menos $_kMinFotos fotos para continuar.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.orange.shade700),
                ),
              ],
            ),
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.camera_alt, color: Colors.green.shade700),
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
                  child: Icon(Icons.photo_library,
                      color: Colors.blue.shade700),
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

// ─── Widget de progreso ──────────────────────────────────────────────────────

class _ProgresoFotos extends StatelessWidget {
  final int count;
  final int minimo;

  const _ProgresoFotos({required this.count, required this.minimo});

  @override
  Widget build(BuildContext context) {
    final completo = count >= minimo;
    final progreso = (count / minimo).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: completo ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              completo ? Colors.green.shade200 : Colors.blue.shade100,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    completo
                        ? Icons.check_circle
                        : Icons.camera_alt_outlined,
                    size: 18,
                    color: completo
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    completo ? '¡Fotos completas!' : 'Fotos registradas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: completo
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                '$count / $minimo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: completo
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: completo
                  ? Colors.green.shade100
                  : Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation(
                completo ? Colors.green.shade600 : Colors.blue.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
