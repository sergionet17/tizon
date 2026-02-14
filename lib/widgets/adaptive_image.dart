import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdaptiveImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AdaptiveImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 🌐 WEB → no Image.file
    if (kIsWeb) {
      // Si es URL remota
      if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: fit,
          width: width,
          height: height,
        );
      }

      // Si es "local" → placeholder
      return Image.asset(
        'assets/images/no_image.png',
        fit: fit,
        width: width,
        height: height,
      );
    }

    // 📱 MOBILE / DESKTOP
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
    );
  }
}
