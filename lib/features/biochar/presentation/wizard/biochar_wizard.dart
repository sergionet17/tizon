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
  bool _cargandoDraft = true;

  @override
  void initState() {
    super.initState();
    _controller = BiocharFormController(fincaId: widget.fincaId);
    _controller.addListener(() => setState(() {}));
    _checkForDraft();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Busca un borrador guardado y ofrece retomarlo.
  Future<void> _checkForDraft() async {
    final draft = await _controller.loadDraft();
    if (!mounted) return;

    if (draft != null) {
      final resume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.restore, color: Color(0xFF1B5E20)),
              SizedBox(width: 10),
              Expanded(
                child: Text('Registro en curso',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: const Text(
            'Tienes un registro sin completar para esta finca.\n¿Deseas continuar donde lo dejaste?',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Empezar de nuevo',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (resume == true) {
        _controller.restoreFromDraft(draft);
        setState(() {
          _pasoActual =
              ((draft['pasoActual'] as int?) ?? 0).clamp(0, _pasos.length - 1);
          _cargandoDraft = false;
        });
      } else {
        await _controller.clearDraft();
        if (mounted) setState(() => _cargandoDraft = false);
      }
    } else {
      setState(() => _cargandoDraft = false);
    }
  }

  // ── AGREGAR PASOS AQUÍ ──────────────────────────────────────────
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
      _controller.saveDraft(_pasoActual); // persiste paso avanzado
    }
  }

  void _anterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
      _controller.saveDraft(_pasoActual); // persiste paso retrocedido
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _guardar() async {
    final id = await _controller.submit();
    if (!mounted) return;
    if (id != null) {
      await _controller.clearDraft(); // borra draft al completar exitosamente
      if (!mounted) return;
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
    // Spinner mientras busca/carga borrador
    if (_cargandoDraft) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8F5E9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    final paso = _pasos[_pasoActual];
    final total = _pasos.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('¿Salir del registro?'),
            content: const Text(
              'Tu progreso se guardará automáticamente y podrás continuarlo después.',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Seguir editando'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Salir',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (salir == true && context.mounted) {
          await _controller.saveDraft(_pasoActual); // garantiza que quede guardado
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        body: SafeArea(
          child: Column(
            children: [
              _WizardHeader(
                pasoActual: _pasoActual,
                totalPasos: total,
                titulo: paso.titulo,
                onBack: _anterior,
              ),
              Expanded(child: paso),
            ],
          ),
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
