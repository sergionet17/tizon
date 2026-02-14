// lib/app/app.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // o tu pantalla root actual

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tizón',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // deja lo mismo que hoy
    );
  }
}
