// lib/services/local_image_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalImageService {
  static final LocalImageService _instance = LocalImageService._internal();
  factory LocalImageService() => _instance;
  LocalImageService._internal();

  /// Guarda una imagen localmente y retorna la ruta
  Future<String> saveImage(File imageFile, String fincaId) async {
    try {
      // Obtener directorio de documentos de la app
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/fincas_images');
      
      // Crear directorio si no existe
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'finca_${fincaId}_$timestamp$extension';
      final newPath = '${imagesDir.path}/$fileName';

      // Copiar el archivo
      final savedImage = await imageFile.copy(newPath);
      return savedImage.path;
    } catch (e) {
      throw Exception('Error al guardar imagen localmente: $e');
    }
  }

  /// Elimina una imagen local
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Verifica si una imagen local existe
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tamaño de una imagen en bytes
  Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Limpia imágenes huérfanas (sin finca asociada)
  Future<void> cleanOrphanImages(List<String> validImagePaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/fincas_images');
      
      if (!await imagesDir.exists()) return;

      final files = await imagesDir.list().toList();
      for (var file in files) {
        if (file is File && !validImagePaths.contains(file.path)) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error al limpiar imágenes huérfanas: $e');
    }
  }
}