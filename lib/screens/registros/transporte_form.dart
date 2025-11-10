import 'package:flutter/material.dart';

class TransporteFormPage extends StatelessWidget {
  const TransporteFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro · Transporte')),
      body: const Center(
        child: Text(
          'Pantalla de Transporte (placeholder)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
