import 'package:flutter/material.dart';
import 'package:tizon_app/models/biochar_batch.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

class StepTipoBiomasa extends WizardStep {
  const StepTipoBiomasa({
    super.key,
    required super.controller,
    required super.onNext,
    required super.onBack,
  });

  @override
  String get titulo => 'Tipo de biomasa';

  @override
  bool get puedeAvanzar => controller.state.tipoBiomasa != null;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return WizardStepBase(
      icono: Icons.forest_outlined,
      iconoColor: const Color(0xFF2E7D32),
      titulo: titulo,
      descripcion: '¿Qué tipo de material usaste para producir el biocarbón?',
      puedeAvanzar: puedeAvanzar,
      onNext: onNext,
      contenido: Column(
        children: [
          _OpcionBiomasa(
            label: 'Madera de soca de café',
            descripcion: 'Ramas y tallos del cultivo de café',
            icono: Icons.coffee_outlined,
            seleccionado: s.tipoBiomasa == TipoBiomasa.maderaSocaCafe,
            onTap: () => controller.setTipoBiomasa(TipoBiomasa.maderaSocaCafe),
          ),
          const SizedBox(height: 12),
          _OpcionBiomasa(
            label: 'Pulpa de café',
            descripcion: 'Residuo del procesamiento del café',
            icono: Icons.spa_outlined,
            seleccionado: s.tipoBiomasa == TipoBiomasa.pulpaCafe,
            onTap: () => controller.setTipoBiomasa(TipoBiomasa.pulpaCafe),
          ),
          const SizedBox(height: 12),
          _OpcionBiomasa(
            label: 'Otro',
            descripcion: 'Otro tipo de biomasa',
            icono: Icons.more_horiz,
            seleccionado: s.tipoBiomasa == TipoBiomasa.otro,
            onTap: () => controller.setTipoBiomasa(TipoBiomasa.otro),
          ),
        ],
      ),
    );
  }
}

class _OpcionBiomasa extends StatelessWidget {
  final String label;
  final String descripcion;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionBiomasa({
    required this.label,
    required this.descripcion,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF1B5E20)
                : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
          boxShadow: seleccionado
              ? [BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: seleccionado
                    ? const Color(0xFF1B5E20).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono,
                  color: seleccionado
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade500,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: seleccionado
                              ? const Color(0xFF1B5E20)
                              : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(descripcion,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (seleccionado)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1B5E20), size: 22),
          ],
        ),
      ),
    );
  }
}
