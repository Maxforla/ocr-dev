// ocr_service.dart — VERSIONE OTTIMIZZATA (720px + upscale ridotto + Tesseract solo fallback)

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:tesseract_ocr/tesseract_ocr.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        debugPrint('📸 FOTO: annullata');
        return null;
      }

      return File(image.path);
    } catch (e) {
      debugPrint('📸 CAMERA ERROR: $e');
      return null;
    }
  }

  Future<String> extractText(File imageFile) async {
    try {
      debugPrint('🔍 OCR START (compute isolate)');

      final RootIsolateToken token = RootIsolateToken.instance!;

      final result = await compute(_performOcrInIsolate, {
        'path': imageFile.path,
        'token': token,
      });

      debugPrint('🧾 TESTO OCR GREZZO (RITORNO ISOLATE):\n$result');

      return result;
    } catch (e) {
      debugPrint('❌ OCR ERROR: $e');
      return '';
    }
  }
}

Future<String> _performOcrInIsolate(Map args) async {
  try {
    debugPrint('🧪 ISOLATE: avviato');

    final String imagePath = args['path'];
    final RootIsolateToken token = args['token'];

    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      debugPrint('❌ ISOLATE: decode fallita');
      return '';
    }

    debugPrint('📏 DIMENSIONI ORIGINALI: ${image.width} x ${image.height}');

    // -------------------------------------------------------------
    // RIDUZIONE A 720 PX (velocità molto maggiore)
    // -------------------------------------------------------------
    const targetWidth = 720;
    final scale = targetWidth / image.width;

    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );

    debugPrint('📏 RIDOTTA A: ${resized.width} x ${resized.height}');

    // -------------------------------------------------------------
    // UPSCALE RIDOTTO (1.2× invece di 1.5×)
    // -------------------------------------------------------------
    final upscaled = img.copyResize(
      resized,
      width: (resized.width * 1.2).round(),
      height: (resized.height * 1.2).round(),
      interpolation: img.Interpolation.linear,
    );

    debugPrint('📏 UPSCALE A: ${upscaled.width} x ${upscaled.height}');

    final upscaledBytes = Uint8List.fromList(
      img.encodeJpg(upscaled, quality: 95),
    );

    final upscaledPath = imagePath.replaceAll('.jpg', '_final.jpg');
    final upscaledFile = File(upscaledPath)..writeAsBytesSync(upscaledBytes);

    // -------------------------------------------------------------
    // MLKIT (PRIORITARIO)
    // -------------------------------------------------------------
    try {
      debugPrint('🔍 MLKIT: start');

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFile(upscaledFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      final mlkitResult = buffer.toString().trim();
      debugPrint('🔍 MLKIT RISULTATO:\n$mlkitResult');

      // Se MLKit trova qualcosa → STOP, niente Tesseract
      if (mlkitResult.isNotEmpty) return mlkitResult;
    } catch (e) {
      debugPrint('❌ MLKIT ERROR: $e');
    }

    // -------------------------------------------------------------
    // TESSERACT (SOLO SE MLKIT FALLISCE)
    // -------------------------------------------------------------
    try {
      debugPrint('🔍 TESSERACT: start');

      final tess = await TesseractOcr.extractText(upscaledFile.path);
      final cleaned = tess.trim();

      debugPrint('🔍 TESSERACT RISULTATO:\n$cleaned');

      if (cleaned.isNotEmpty) return cleaned;
    } catch (e) {
      debugPrint('❌ TESSERACT ERROR: $e');
    }

    return '';
  } catch (e) {
    debugPrint('❌ ISOLATE FATAL ERROR: $e');
    return '';
  }
}