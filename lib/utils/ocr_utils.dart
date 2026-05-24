import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  /// Riduce la risoluzione dell'immagine a 720px lato lungo
  /// Perfetto per OCR su scontrini
  static Future<Uint8List> compressTo720(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 720,
      minHeight: 720,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}