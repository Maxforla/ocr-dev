import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    return File(image.path);
  }

  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return File(image.path);
  }

  Future<String> extractText(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("File immagine non trovato");
      }

      final length = await imageFile.length();
      if (length == 0) {
        throw Exception("File immagine vuoto");
      }

      // 1) PRIMO TENTATIVO: MLKit
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
         print("=== OCR RAW TEXT ===");
         print(recognizedText.text);
 
      await textRecognizer.close();

      String raw = recognizedText.text.trim();

      // 2) Se MLKit ha trovato qualcosa, lo usiamo
      if (raw.isNotEmpty) {
        return _postProcessText(raw);
      }

      // 3) FALLBACK: Tesseract
debugPrint("MLKit vuoto, passo a Tesseract...");

final tessText = await TesseractOcr.extractText(imageFile.path);

final cleaned = tessText.trim();

debugPrint("TESSERACT OCR RAW:\n$cleaned");

if (cleaned.isEmpty) {
  debugPrint("Tesseract vuoto");
  return "";
}

      return _postProcessText(cleaned);
    } catch (e) {
      debugPrint("ERRORE OCR: $e");
      return "";
    }
  }

  /// Piccolo post-processing del testo grezzo
  String _postProcessText(String text) {
    var t = text;

    // Normalizza fine riga
    t = t.replaceAll('\r\n', '\n');

    // Correzioni caratteri tipici OCR
    t = t.replaceAll('O', '0'); // O maiuscola → zero
    t = t.replaceAll('o ', '0 '); // o seguita da spazio in contesto numerico
    t = t.replaceAll('I', '1'); // I maiuscola → 1 in contesti numerici

    // Rimuovi righe completamente vuote multiple
    final righe = t.split('\n');
    final pulite = <String>[];
    for (final r in righe) {
      final trimmed = r.trimRight();
      if (trimmed.isEmpty && pulite.isNotEmpty && pulite.last.isEmpty) {
        continue;
      }
      pulite.add(trimmed);
    }

    return pulite.join('\n').trim();
  }
}
