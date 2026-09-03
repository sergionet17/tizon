import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tizon_app/features/biochar/presentation/controller/biochar_form_controller.dart';
import 'package:tizon_app/features/biochar/presentation/wizard/biochar_wizard.dart';
import 'wizard_step_base.dart';

class StepTemperatura extends WizardStep {
  const StepTemperatura({
    super.key,
    required super.controller,
    required super.onNext,
    required super.onBack,
  });

  @override
  String get titulo => 'Temperatura de quema';

  @override
  bool get puedeAvanzar =>
      controller.state.temperatura != null &&
      controller.state.temperatura! > 0;

  @override
  Widget build(BuildContext context) {
    return _StepTemperaturaBody(
      controller: controller,
      onNext: onNext,
      titulo: titulo,
    );
  }
}

class _StepTemperaturaBody extends StatefulWidget {
  final BiocharFormController controller;
  final VoidCallback onNext;
  final String titulo;

  const _StepTemperaturaBody({
    required this.controller,
    required this.onNext,
    required this.titulo,
  });

  bool get puedeAvanzar =>
      controller.state.temperatura != null &&
      controller.state.temperatura! > 0;

  @override
  State<_StepTemperaturaBody> createState() => _StepTemperaturaBodyState();
}

class _StepTemperaturaBodyState extends State<_StepTemperaturaBody> {
  final _textController = TextEditingController();

  static const _presets = [300, 350, 400, 450, 500, 600];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _selectPreset(int temp) {
    widget.controller.setTemperatura(temp.toString());
    setState(() {
      _textController.text = temp.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final temp = widget.controller.state.temperatura;

    return WizardStepBase(
      icono: Icons.thermostat_outlined,
      iconoColor: const Color(0xFFE65100),
      titulo: widget.titulo,
      descripcion: '¿A qué temperatura se realizó la carbonización?',
      puedeAvanzar: widget.puedeAvanzar,
      onNext: widget.onNext,
      contenido: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _textController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    widget.controller.setTemperatura(v);
                    setState(() {});
                  },
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '350',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                    suffixText: '°C',
                    suffixStyle: TextStyle(
                        fontSize: 24, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(
                          color: Color(0xFF1B5E20), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Presets rápidos
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Valores comunes',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((t) {
                    final selected = temp != null && temp.toInt() == t;
                    return GestureDetector(
                      onTap: () => _selectPreset(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE65100)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFE65100)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          '$t°C',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                // Rangos de referencia
                Row(
                  children: [
                    _RangoChip(label: 'Baja', rango: '200-300°C',
                        color: Colors.blue.shade400),
                    const SizedBox(width: 8),
                    _RangoChip(label: 'Media', rango: '300-500°C',
                        color: Colors.orange.shade400),
                    const SizedBox(width: 8),
                    _RangoChip(label: 'Alta', rango: '500-700°C',
                        color: Colors.red.shade400),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangoChip extends StatelessWidget {
  final String label;
  final String rango;
  final Color color;
  const _RangoChip({
    required this.label,
    required this.rango,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(rango,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
