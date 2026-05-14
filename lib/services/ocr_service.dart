import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Scatta una foto con la fotocamera
  Future<File?> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    return File(image.path);
  }

  /// Seleziona una foto dalla galleria
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return File(image.path);
  }

  /// Esegue l'OCR e restituisce il testo grezzo
  Future<String> extractText(File imageFile) async {
    try {
      // 1. Controllo file esistente
      if (!await imageFile.exists()) {
        throw Exception("File immagine non trovato");
      }

      // 2. Controllo dimensione > 0
      final length = await imageFile.length();
      if (length == 0) {
        throw Exception("File immagine vuoto");
      }

      // 3. OCR
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(imageFile);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      return recognizedText.text;
    } catch (e) {
      debugPrint("ERRORE OCR: $e");
      return "";
    }
  }
}