import 'package:flutter/material.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'steps/step_tipo_biomasa.dart';
import 'steps/step_foto_biomasa.dart';
import 'steps/step_temperatura.dart';
import 'steps/step_fotos_humedad.dart';
import 'steps/step_resumen.dart';

/// WizardStep — contrato que debe cumplir cada paso.
/// Para agregar un paso nuevo: crear una clase que extienda WizardStep
/// y agregarla a la lista _steps() en BiocharWizard.
abstract class WizardStep extends StatelessWidget {
  final BiocharFormController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const WizardStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  /// Título que aparece en la barra de progreso
  String get titulo;

  /// Si el paso está completo para habilitar "Siguiente"
  bool get puedeAvanzar;
}

class BiocharWizard extends StatefulWidget {
  final int fincaId;
  const BiocharWizard({super.key, required this.fincaId});

  @override
  State<BiocharWizard> createState() => _BiocharWizardState();
}

class _BiocharWizardState extends State<BiocharWizard> {
  late final BiocharFormController _controller;
  int _pasoActual = 0;

  @override
  void initState() {
    super.initState();
    _controller = BiocharFormController(fincaId: widget.fincaId);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── AGREGAR PASOS AQUÍ ──────────────────────────────────────────
  // Para agregar un paso nuevo: crear el widget en wizard/steps/
  // y agregarlo a esta lista. El wizard se adapta automáticamente.
  List<WizardStep> get _pasos => [
    StepTipoBiomasa(
      controller: _controller,
      onNext: _siguiente,
      onBack: _anterior,
    ),
    StepFotoBiomasa(
      controller: _controller,
      onNext: _siguiente,
      onBack: _anterior,
    ),
    StepTemperatura(
      controller: _controller,
      onNext: _siguiente,
      onBack: _anterior,
    ),
    StepFotosHumedad(
      controller: _controller,
      onNext: _siguiente,
      onBack: _anterior,
    ),
    StepResumen(
      controller: _controller,
      onNext: _guardar,
      onBack: _anterior,
    ),
  ];

  void _siguiente() {
    if (_pasoActual < _pasos.length - 1) {
      setState(() => _pasoActual++);
    }
  }

  void _anterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _guardar() async {
    final id = await _controller.submit();
    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro guardado. Se sincroniza cuando haya internet.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_pasoActual];
    final total = _pasos.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header con progreso
            _WizardHeader(
              pasoActual: _pasoActual,
              totalPasos: total,
              titulo: paso.titulo,
              onBack: _anterior,
            ),
            // Contenido del paso actual
            Expanded(child: paso),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final int pasoActual;
  final int totalPasos;
  final String titulo;
  final VoidCallback onBack;

  const _WizardHeader({
    required this.pasoActual,
    required this.totalPasos,
    required this.titulo,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = (pasoActual + 1) / totalPasos;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Paso ${pasoActual + 1} de $totalPasos',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Puntos indicadores
              Row(
                children: List.generate(totalPasos, (i) {
                  final activo = i == pasoActual;
                  final completado = i < pasoActual;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: activo ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: completado || activo
                          ? const Color(0xFF1B5E20)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1B5E20)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
