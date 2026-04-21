import 'package:flutter/material.dart';

/// Base visual para todos los pasos del wizard.
/// Cada paso tiene: ícono + título + descripción + contenido + botón siguiente.
class WizardStepBase extends StatelessWidget {
  final IconData icono;
  final Color iconoColor;
  final String titulo;
  final String descripcion;
  final Widget contenido;
  final String labelBoton;
  final bool puedeAvanzar;
  final bool cargando;
  final VoidCallback onNext;
  final bool esUltimoPaso;

  const WizardStepBase({
    super.key,
    required this.icono,
    required this.iconoColor,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.puedeAvanzar,
    required this.onNext,
    this.labelBoton = 'Siguiente',
    this.cargando = false,
    this.esUltimoPaso = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono del paso
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icono, color: iconoColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(descripcion,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4)),
                const SizedBox(height: 24),
                contenido,
              ],
            ),
          ),
        ),

        // Botón siguiente fijo abajo
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (puedeAvanzar && !cargando) ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: cargando
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(labelBoton,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        if (!esUltimoPaso) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
