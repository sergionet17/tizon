import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tizon_app/models/biochar_batch.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

class StepResumen extends WizardStep {
  const StepResumen({
    super.key,
    required super.controller,
    required super.onNext,
    required super.onBack,
  });

  @override
  String get titulo => 'Resumen';

  @override
  bool get puedeAvanzar => !controller.state.loading;

  String _tipoBiomasaLabel(TipoBiomasa? t) {
    switch (t) {
      case TipoBiomasa.maderaSocaCafe: return 'Madera de soca de café';
      case TipoBiomasa.pulpaCafe:      return 'Pulpa de café';
      case TipoBiomasa.otro:           return 'Otro';
      default:                          return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return WizardStepBase(
      icono: Icons.checklist_outlined,
      iconoColor: const Color(0xFF1B5E20),
      titulo: titulo,
      descripcion: 'Revisa la información antes de guardar el registro.',
      puedeAvanzar: puedeAvanzar,
      cargando: s.loading,
      onNext: onNext,
      labelBoton: 'Guardar registro',
      esUltimoPaso: true,
      contenido: Column(
        children: [
          // Foto biomasa
          if (s.biomasaImage != null)
            Container(
              height: 160,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(s.biomasaImage!.path, fit: BoxFit.cover)
                    : Image.file(File(s.biomasaImage!.path),
                        fit: BoxFit.cover),
              ),
            ),

          // Datos del registro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _FilaResumen(
                  icono: Icons.forest_outlined,
                  label: 'Tipo de biomasa',
                  valor: _tipoBiomasaLabel(s.tipoBiomasa),
                ),
                const Divider(height: 20),
                _FilaResumen(
                  icono: Icons.thermostat_outlined,
                  label: 'Temperatura',
                  valor: s.temperatura != null
                      ? '${s.temperatura}°C'
                      : 'No registrada',
                ),
                const Divider(height: 20),
                _FilaResumen(
                  icono: Icons.camera_alt_outlined,
                  label: 'Foto biomasa',
                  valor: s.biomasaImage != null ? '✓ Lista' : 'Sin foto',
                  colorValor: s.biomasaImage != null
                      ? Colors.green.shade700
                      : Colors.red,
                ),
                const Divider(height: 20),
                _FilaResumen(
                  icono: Icons.water_drop_outlined,
                  label: 'Fotos humedad',
                  valor: '${s.humedadImages.length} foto${s.humedadImages.length != 1 ? 's' : ''}',
                ),
              ],
            ),
          ),

          if (s.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se guardará localmente y se sincronizará con Firebase cuando haya internet.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.green.shade700),
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

class _FilaResumen extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final Color? colorValor;

  const _FilaResumen({
    required this.icono,
    required this.label,
    required this.valor,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ),
        Text(valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorValor ?? Colors.black87,
            )),
      ],
    );
  }
}
