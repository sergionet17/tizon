import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/connectivity_indicator.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _cedula = TextEditingController();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;
  bool _isRegistering = false;
  String? _error;

  Future<void> _handleCedulaSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = '${_cedula.text.trim()}@tizon.app';
    final password = _pass1.text.trim();

    final err = _isRegistering
        ? await _auth.registerEmail(email, password)
        : await _auth.signInEmail(email, password);

    if (err == 'NO_LOCAL_USER') {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off, size: 60, color: Colors.orange.shade700),
                const SizedBox(height: 20),
                const Text(
                  'Usuario no registrado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No tenemos registro de este usuario en el dispositivo.\n'
                  'Puedes crear una cuenta ahora y se sincronizará automáticamente cuando haya conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Crear cuenta'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm == true) {
        var box = await Hive.openBox('usuarios');
        final users = box.get('usuarios_local', defaultValue: []) as List;
        users.add({'email': email, 'password': password});
        await box.put('usuarios_local', users);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }

      setState(() => _loading = false);
      return;
    }

    if (err == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() => _error = err);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Stack(
          children: [
            _buildBackground(),
            _buildContent(),
            ConnectivityIndicator(isOnline: isOnline),
          ],
        );
      },
    );
  }

  // ✅ Fondo verde oscuro con estilo fluorescente
  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1F0F), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  // ✅ Contenido principal
  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ✅ Logo + nombre + rombo fluorescente
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tizón SAS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.hexagon_outlined,
                        size: 30, color: Colors.greenAccent.shade400),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Compensa tu huella de carbono.\nConecta con proyectos sostenibles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),

                const SizedBox(height: 40),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Tarjeta blanca elegante
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),

            if (_error != null) _buildError(),

            _buildCedulaField(),
            const SizedBox(height: 20),

            _buildPasswordField(),
            const SizedBox(height: 20),

            if (_isRegistering) _buildConfirmPasswordField(),

            _buildSubmitButton(),
            _buildToggleButton(),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  // ✅ Error estilizado
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Campo cédula
  Widget _buildCedulaField() {
    return TextFormField(
      controller: _cedula,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: _inputDecoration('Ingresa tu número de cédula'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu cédula';
        if (v.length < 6) return 'Cédula inválida';
        return null;
      },
    );
  }

  // ✅ Campo contraseña
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _pass1,
      obscureText: true,
      decoration: _inputDecoration('Ingresa tu contraseña'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  // ✅ Campo confirmar contraseña
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _pass2,
      obscureText: true,
      decoration: _inputDecoration('Repite tu contraseña'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirma tu contraseña';
        if (v != _pass1.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }

  // ✅ Estilo inputs
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade100.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ✅ Botón ingresar
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _handleCedulaSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isRegistering ? 'Registrar' : 'Ingresar',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  // ✅ Botón cambiar entre login/registro
  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isRegistering = !_isRegistering;
            _error = null;
            _pass2.clear();
          });
        },
        child: Text(
          _isRegistering
              ? '¿Ya tienes cuenta? Inicia sesión'
              : '¿No tienes cuenta? Regístrate',
          style: TextStyle(
            fontSize: 15,
            color: Colors.green.shade800,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ✅ Botón Google
  Widget _buildGoogleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : () => _auth.signInWithGoogle(),
          icon: const Icon(Icons.g_mobiledata,
              color: Colors.black87, size: 24),
          label: const Text(
            'Continuar con Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}