// ocr_flow.dart — VERSIONE COMPATIBILE CON OCR ENGINE AVANZATO

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'ocr_service.dart';
import 'ocr_parser.dart';

import '../models/movimento.dart';
import '../pages/dettaglio_movimento_page.dart';
import '../pages/ocr_loading_page.dart';

import '../utils/normalize_smart.dart';
import '../utils/database_helper.dart';

class OcrFlow {
  /// Funzione top-level per compute()
  /// Deve essere SINCRONA e restituire OcrResult
  static OcrResult _parseInIsolate(String text) {
    // ATTENZIONE: parse() è async → NON si può usare qui
    // Usiamo il metodo sincrono interno del parser
    return OcrParser.internalParseSync(text);
  }

  /// Flusso OCR completo
  static Future<Movimento?> scan(BuildContext context) async {
    try {
      final ocr = OcrService();

      // 1) Mostra pagina di loading
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OcrLoadingPage()),
      );

      // 2) Scatta la foto
      final imageFile = await ocr.takePhoto();
      if (imageFile == null) {
        Navigator.pop(context);
        return null;
      }

      // 3) OCR
      final rawText = await ocr.extractText(imageFile);

      // 4) Parsing in isolate
      final parsed = await compute(_parseInIsolate, rawText);

      // 5) Nota pulita
      final notaPulita = normalizeSmart(rawText);

      // 6) Movimento precompilato
      final nuovoMovimento = Movimento(
        id: null,
        tipo: MovimentoTipo.uscita,

        data: parsed.data ?? DateTime.now(),

        categoria: parsed.categoria ?? "Da scontrino",
        descrizione: parsed.descrizione ?? "Spesa rilevata da OCR",

        importo: parsed.importo ?? 0.0,

        puntoVendita: parsed.puntoVendita ?? "",
        metodoPagamento: parsed.metodoPagamento ?? "",

        nota: notaPulita,
        articoli: "",

        origine: OrigineDati.ocr,

        searchCategoria: normalizeSmart(parsed.categoria ?? "Da scontrino"),
        searchDescrizione:
            normalizeSmart(parsed.descrizione ?? "Spesa rilevata da OCR"),
        searchPuntoVendita: normalizeSmart(parsed.puntoVendita ?? ""),
        searchMetodoPagamento:
            normalizeSmart(parsed.metodoPagamento ?? ""),

        dataCreazione: DateTime.now(),
        idMacroarea: 0,
      );

      // 7) Chiudi loading e apri pagina dettaglio
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DettaglioMovimentoPage(movimento: nuovoMovimento),
        ),
      );

      // 8) Attendi eventuale conferma dell’utente
      final risultato = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DettaglioMovimentoPage(movimento: nuovoMovimento),
        ),
      );

      // 9) Salvataggio solo se confermato
      if (risultato is Movimento) {
        await DatabaseHelper.instance.insertMovimento(risultato);
        return risultato;
      }

      return null;

    } catch (e, stack) {
      print("OCR ERROR: $e");
      print("STACK: $stack");

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore durante la scansione OCR")),
      );

      return null;
    }
  }
}