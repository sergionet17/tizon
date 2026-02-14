import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/biochar_batch.dart';
import '../../../../models/biochar_media.dart';
import '../../../../models/common.dart';
import '../../../../services/biochar_local_db_service.dart';
import '../../../../services/local_image_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/sync_service.dart';

class BiocharFormState {
  final bool loading;
  final String? error;

  final TipoBiomasa? tipoBiomasa;
  final int? humedadEntrada; // 0..100
  final int? temperatura; // requerida

  final XFile? biomasaImage;
  final List<XFile> humedadImages;

  const BiocharFormState({
    this.loading = false,
    this.error,
    this.tipoBiomasa,
    this.humedadEntrada,
    this.temperatura,
    this.biomasaImage,
    this.humedadImages = const [],
  });

  bool get isValid {
    if (tipoBiomasa == null) return false;
    if (temperatura == null || temperatura! <= 0) return false;
    if (biomasaImage == null) return false;
    if (humedadEntrada != null &&
        (humedadEntrada! < 0 || humedadEntrada! > 100)) return false;
    return true;
  }

  BiocharFormState copyWith({
    bool? loading,
    String? error,
    TipoBiomasa? tipoBiomasa,
    int? humedadEntrada,
    int? temperatura,
    XFile? biomasaImage,
    List<XFile>? humedadImages,
    bool clearError = false,
  }) {
    return BiocharFormState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      tipoBiomasa: tipoBiomasa ?? this.tipoBiomasa,
      humedadEntrada: humedadEntrada ?? this.humedadEntrada,
      temperatura: temperatura ?? this.temperatura,
      biomasaImage: biomasaImage ?? this.biomasaImage,
      humedadImages: humedadImages ?? this.humedadImages,
    );
  }
}

class BiocharFormController extends ChangeNotifier {
  final int fincaId; // local finca id
  final BiocharLocalDbService _db = BiocharLocalDbService();
  final LocalImageService _imageService = LocalImageService();
  final ImagePicker _picker = ImagePicker();

  BiocharFormState _state = const BiocharFormState();
  BiocharFormState get state => _state;

  BiocharFormController({required this.fincaId});

  void setTipoBiomasa(TipoBiomasa tipo) {
    _state = _state.copyWith(tipoBiomasa: tipo, clearError: true);
    notifyListeners();
  }

  void setHumedadEntrada(String raw) {
    final v = int.tryParse(raw.trim());
    _state = _state.copyWith(humedadEntrada: v, clearError: true);
    notifyListeners();
  }

  void setTemperatura(String raw) {
    final v = int.tryParse(raw.trim());
    _state = _state.copyWith(temperatura: v, clearError: true);
    notifyListeners();
  }

  Future<void> pickBiomasaImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file != null) {
      _state = _state.copyWith(biomasaImage: file, clearError: true);
      notifyListeners();
    }
  }

  Future<void> addHumedadImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file != null) {
      final list = [..._state.humedadImages, file];
      _state = _state.copyWith(humedadImages: list, clearError: true);
      notifyListeners();
    }
  }

  void removeHumedadAt(int idx) {
    final list = [..._state.humedadImages]..removeAt(idx);
    _state = _state.copyWith(humedadImages: list, clearError: true);
    notifyListeners();
  }

  Future<int?> submit() async {
    if (!_state.isValid) {
      _state = _state.copyWith(error: 'Completa los campos obligatorios (*)');
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(loading: true, clearError: true);
    notifyListeners();

    try {
      // 1) crear batch local
      final batch = BiocharBatch(
        fincaId: fincaId,
        tipoBiomasa: _state.tipoBiomasa!,
        humedadEntrada: _state.humedadEntrada,
        temperaturaQuema: _state.temperatura!,
        estadoSinc: EstadoSincronizacion.pendiente,
      );

      final batchId = await _db.saveBatch(batch);

      // 2) persistir imagen biomasa
      final biomasaPath =
          await _persistXFile(_state.biomasaImage!, 'biochar_biomasa_$batchId');
      await _db.saveMedia(
        BiocharMedia(
          batchId: batchId,
          tipo: TipoBiocharMedia.biomasa,
          rutaLocal: biomasaPath,
          estadoSinc: EstadoSincronizacion.pendiente,
        ),
      );

      // 3) persistir imágenes humedad
      for (int i = 0; i < _state.humedadImages.length; i++) {
        final p = await _persistXFile(
            _state.humedadImages[i], 'biochar_humedad_${batchId}_$i');
        await _db.saveMedia(
          BiocharMedia(
            batchId: batchId,
            tipo: TipoBiocharMedia.humedad,
            rutaLocal: p,
            estadoSinc: EstadoSincronizacion.pendiente,
          ),
        );
      }

      // 4) si hay internet, dispara sync (usa tu SyncService actual)
      if (ConnectivityService().isOnline) {
        // si tu SyncService ya hace syncAll, esto entra en tu pipeline
        await SyncService().syncAll();
      }

      _state = _state.copyWith(loading: false);
      notifyListeners();
      return batchId;
    } catch (e) {
      _state = _state.copyWith(loading: false, error: '$e');
      notifyListeners();
      return null;
    }
  }

  // --- Helpers ---
  Future<String> _persistXFile(XFile x, String name) async {
    // En web NO existe File real: guardamos la "ruta" tipo blob:... y listo (sin persistencia real).
    // En móvil guardamos a disco con tu LocalImageService.
    if (kIsWeb) {
      return x
          .path; // blob url. Para persistencia real web, toca subir directo o usar IndexedDB.
    } else {
      final f = File(x.path);
      return await _imageService.saveImage(f, name);
    }
  }
}
