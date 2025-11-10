import 'dart:developer' as dev;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/finca_form_data.dart';

class FincaService {
  static const _boxName = 'app_data';
  static const _keyActive = 'finca_activa';
  static const _keyList = 'fincas_list';

  Future<bool> hasActive() async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(_keyActive);
    final ok = data is Map && (data['nombreFinca']?.toString().isNotEmpty ?? false);
    dev.log('hasActive=$ok', name: 'Tizon.FincaService');
    return ok;
  }

  Future<FincaFormData?> getActive() async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(_keyActive);
    if (data is Map) {
      dev.log('getActive OK', name: 'Tizon.FincaService');
      return FincaFormData.fromJson(Map<String, dynamic>.from(data));
    }
    dev.log('getActive NULL', name: 'Tizon.FincaService');
    return null;
  }

  Future<void> setActive(FincaFormData finca) async {
    final box = await Hive.openBox(_boxName);

    // Guarda finca activa
    await box.put(_keyActive, finca.toJson());

    // Mantén un historial simple
    final list = (box.get(_keyList) as List?)?.cast<Map>().toList() ?? <Map>[];
    list.add(finca.toJson());
    await box.put(_keyList, list);

    dev.log('setActive guardada: ${finca.nombreFinca} / ${finca.productor}', name: 'Tizon.FincaService');
  }

  /// Limpia finca activa (no borra el historial)
  Future<void> clearActive() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_keyActive);
    dev.log('clearActive', name: 'Tizon.FincaService');
  }
}
