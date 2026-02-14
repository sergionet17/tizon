import 'package:hive_flutter/hive_flutter.dart';

import '../models/common.dart';
import '../models/finca.dart';
import '../models/encuesta.dart';
import '../models/medio.dart';
import '../models/biochar_batch.dart';
import '../models/biochar_media.dart';

class HiveInit {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(EstadoSincronizacionAdapter());
    Hive.registerAdapter(TipoMedioAdapter());
    Hive.registerAdapter(LatLngAdapter());

    Hive.registerAdapter(TipoBiomasaAdapter());
    Hive.registerAdapter(BiocharBatchAdapter());
    Hive.registerAdapter(TipoBiocharMediaAdapter());
    Hive.registerAdapter(BiocharMediaAdapter());

    Hive.registerAdapter(FincaAdapter());
    Hive.registerAdapter(EncuestaAdapter());
    Hive.registerAdapter(MedioAdapter());

    await Hive.openBox<Finca>('fincas');
    await Hive.openBox<Encuesta>('encuestas');
    await Hive.openBox<Medio>('medios');
  }
}
