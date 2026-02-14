import 'package:flutter/material.dart';

// ✅ Logger central (ajusta la ruta si es diferente)
import 'package:tizon_app/core/logger/app_logger.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Log una sola vez al entrar a la pantalla
    final time = DateTime.now();
    print(
        "🚀 [${time.hour}:${time.minute}:${time.second}] Accediendo a dashboard");
    debugPrint("🚨 PRUEBA CRÍTICA: ENTRANDO A INIT");
    logScreen(
      screenName: 'DashboardScreen',
      fileName: 'dashboard_screen.dart',
    );
  }

  @override
  Widget build(BuildContext context) {
    print("👀 El build de Dashboard se está ejecutando");
    debugPrint("🚨 PRUEBA CRÍTICA: ENTRANDO A DASHBOARD");
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Empezar a registrar',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí verás tus estadísticas\ny proyectos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
