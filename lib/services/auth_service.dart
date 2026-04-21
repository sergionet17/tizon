import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tizon_app/features/auth/domain/auth_repository.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'package:tizon_app/app/di.dart';

class AuthService implements AuthRepository {
  final FirebaseAuth _auth       = FirebaseAuth.instance;
  final FirebaseFirestore _fs    = FirebaseFirestore.instance;
  final ConnectivityService _con = getIt<ConnectivityService>();
  final SyncService _sync        = getIt<SyncService>();

  static const _boxName          = 'usuarios';
  static const _keyPendientes    = 'pendientes_sync';
  static const _keySesionActual  = 'sesion_actual';

  Future<Box> get _box async => Hive.openBox(_boxName);

  // ── Device ID ────────────────────────────────────────────────────

  Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return android.id; // ID único del dispositivo Android
  }

  // ── Sesión activa ─────────────────────────────────────────────────

  Future<String?> getSesionActual() async {
    final box = await _box;
    return box.get(_keySesionActual) as String?;
  }

  Future<void> _guardarSesionActual(String cedula) async {
    final box = await _box;
    await box.put(_keySesionActual, cedula);
  }

  Future<void> _borrarSesionActual() async {
    final box = await _box;
    await box.delete(_keySesionActual);
  }

  // ── Pendientes de sync ────────────────────────────────────────────

  Future<void> _agregarPendienteSync(String cedula, String password) async {
    final box = await _box;
    final pendientes = List<Map>.from(
        box.get(_keyPendientes, defaultValue: <Map>[]));
    final yaExiste = pendientes.any((u) => u['cedula'] == cedula);
    if (!yaExiste) {
      pendientes.add({'cedula': cedula, 'password': password});
      await box.put(_keyPendientes, pendientes);
    }
  }

  // ── Registrar deviceId en Firestore ──────────────────────────────

  Future<void> _registrarDispositivo(String cedula) async {
    try {
      final deviceId = await getDeviceId();
      final info     = DeviceInfoPlugin();
      final android  = await info.androidInfo;
      final modelo   = '${android.brand} ${android.model}';

      final ref = _fs.collection('usuarios').doc(cedula);
      await ref.set({
        'cedula': cedula,
        'dispositivos': FieldValue.arrayUnion([
          {
            'deviceId':   deviceId,
            'modelo':     modelo,
            'registrado': DateTime.now().toIso8601String(),
            'activo':     true,
          }
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      // Si falla (sin internet) se reintentará en la próxima sync
      print('[DEVICE] No se pudo registrar dispositivo: $e');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────

  Future<String?> signInEmail(String cedula, String password) async {
    final email = '$cedula@tizon.app';

    // LOGIN ONLINE
    if (_con.isOnline) {
      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        await _guardarSesionActual(cedula);
        await _registrarDispositivo(cedula);
        return null;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found')     return 'Cédula no registrada.';
        if (e.code == 'wrong-password')     return 'Contraseña incorrecta.';
        if (e.code == 'invalid-credential') return 'Cédula o contraseña incorrecta.';
        return e.message;
      }
    }

    // LOGIN OFFLINE
    // Solo permite entrar si esta cédula ya inició sesión antes en este dispositivo
    final sesionPrevia = await getSesionActual();
    final box = await _box;
    final pendientes = List<Map>.from(
        box.get(_keyPendientes, defaultValue: <Map>[]));

    // ¿Se registró offline en este dispositivo?
    final enPendientes = pendientes.any((u) =>
        u['cedula'] == cedula && u['password'] == password);

    if (enPendientes) {
      await _guardarSesionActual(cedula);
      print('[OFFLINE] Login exitoso (pendiente sync): $cedula');
      return null;
    }

    // ¿Es el último usuario que se logueó con internet en este dispositivo?
    if (sesionPrevia == cedula) {
      print('[OFFLINE] Sesión previa encontrada: $cedula');
      return null;
    }

    return 'Sin conexión. Solo puedes ingresar con la cédula que usaste la última vez en este dispositivo.';
  }

  // ── Registro ──────────────────────────────────────────────────────

  Future<String?> registerEmail(String cedula, String password) async {
    final email = '$cedula@tizon.app';

    // REGISTRO ONLINE
    if (_con.isOnline) {
      try {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        await _guardarSesionActual(cedula);
        await _registrarDispositivo(cedula);
        return null;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') return 'Esta cédula ya está registrada.';
        return e.message;
      }
    }

    // REGISTRO OFFLINE
    await _agregarPendienteSync(cedula, password);
    await _guardarSesionActual(cedula);
    print('[OFFLINE] Cédula registrada offline: $cedula');
    return null;
  }

  // ── Google (mantener por compatibilidad) ──────────────────────────

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Inicio de sesión cancelado';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final email  = result.user?.email ?? '';
      // Para Google usamos el email completo como identificador
      await _guardarSesionActual(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Sync pendientes → Firebase ────────────────────────────────────

  @override
  Future<void> syncOfflineUsers() async {
    if (!_con.isOnline) return;

    final box = await _box;
    final pendientes = List<Map>.from(
        box.get(_keyPendientes, defaultValue: <Map>[]));

    if (pendientes.isEmpty) return;

    _sync.startSync();
    final fallidos = <Map>[];

    for (final user in pendientes) {
      // Limpiar cédula por si acaso viene con @tizon.app de versiones anteriores
      var cedula = (user['cedula'] ?? user['email'] ?? '').toString();
      cedula = cedula.replaceAll('@tizon.app', '').trim();
      final password = (user['password'] ?? '').toString();
      final email    = '$cedula@tizon.app';

      try {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        await _registrarDispositivo(cedula);
        print('[SYNC] Cédula creada en Firebase: $cedula');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            await _auth.signInWithEmailAndPassword(
                email: email, password: password);
            await _registrarDispositivo(cedula);
            print('[SYNC] Cédula ya existía, login exitoso: $cedula');
          } catch (_) {
            fallidos.add(user);
          }
        } else {
          fallidos.add(user);
        }
      }
    }

    await box.put(_keyPendientes, fallidos);
    _sync.endSync();
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _borrarSesionActual();
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // ── Contrato AuthRepository ───────────────────────────────────────

  @override
  Future<void> signIn(String email, String password) async {
    final err = await signInEmail(email, password);
    if (err != null) throw Exception(err);
  }

  @override
  Future<void> register(String email, String password) async {
    final err = await registerEmail(email, password);
    if (err != null) throw Exception(err);
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
}
