import 'package:hive/hive.dart';
import '../models/biochar_batch.dart';
import '../models/biochar_media.dart';
import '../models/common.dart';

class BiocharLocalDbService {
  static final BiocharLocalDbService _instance =
      BiocharLocalDbService._internal();
  factory BiocharLocalDbService() => _instance;
  BiocharLocalDbService._internal();

  static const _batchesBox = 'biochar_batches';
  static const _mediaBox = 'biochar_media';

  Future<Box<BiocharBatch>> _batches() async =>
      Hive.openBox<BiocharBatch>(_batchesBox);
  Future<Box<BiocharMedia>> _media() async =>
      Hive.openBox<BiocharMedia>(_mediaBox);

  Future<int> saveBatch(BiocharBatch batch) async {
    final b = await _batches();
    if (batch.id != null) {
      await b.put(batch.id!, batch);
      return batch.id!;
    } else {
      final newKey = await b.add(batch);
      batch.id = newKey;
      await b.put(newKey, batch);
      return newKey;
    }
  }

  Future<BiocharBatch?> getBatch(int id) async {
    final b = await _batches();
    return b.get(id);
  }

  Future<List<BiocharBatch>> getBatchesByFinca(int fincaId) async {
    final b = await _batches();
    final list = b.values.where((x) => x.fincaId == fincaId).toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<int> saveMedia(BiocharMedia media) async {
    final b = await _media();
    if (media.id != null) {
      await b.put(media.id!, media);
      return media.id!;
    } else {
      final newKey = await b.add(media);
      media.id = newKey;
      await b.put(newKey, media);
      return newKey;
    }
  }

  Future<List<BiocharMedia>> getMediaByBatch(int batchId) async {
    final b = await _media();
    final list = b.values.where((m) => m.batchId == batchId).toList();
    list.sort((a, b) =>
        (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return list;
  }

  Future<List<BiocharBatch>> getBatchesPendientes() async {
    final b = await _batches();
    return b.values
        .where((x) => x.estadoSinc == EstadoSincronizacion.pendiente)
        .toList();
  }

  Future<List<BiocharMedia>> getMediaPendiente() async {
    final b = await _media();
    return b.values
        .where((x) => x.estadoSinc == EstadoSincronizacion.pendiente)
        .toList();
  }
}
