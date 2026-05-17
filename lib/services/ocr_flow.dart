import 'package:flutter/material.dart';
import 'ocr_service.dart';
import 'ocr_parser.dart';
import '../database_helper.dart';
import '../models/movimento.dart';
import '../pages/dettaglio_movimento_page.dart';
import '../utils/normalize_smart.dart';

class OcrFlow {
  static Future<Movimento?> scan(BuildContext context) async {
    try {
      final ocr = OcrService();
      final parser = OcrParser();

      // 1) Scatta la foto
      final image = await ocr.takePhoto();
      if (image == null) return null;

      // 2) OCR
      final rawText = await ocr.extractText(image);
      if (rawText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossibile leggere lo scontrino")),
        );
        return null;
      }

      // 3) Parsing
      final parsed = await parser.parse(rawText);

      // 4) Nota pulita
      final notaPulita = parser.pulisciNotaOCR(rawText);

      // 5) Movimento precompilato
      final nuovoMovimento = Movimento(
  id: null,
  tipo: MovimentoTipo.uscita,

  // 🔥 DATA (convertita correttamente)
  data: (parsed.data ?? DateTime.now()),

  categoria: parsed.categoria ?? "Da scontrino",
  descrizione: parsed.descrizione ?? "Spesa rilevata da OCR",
  importo: parsed.importo ?? 0.0,
  puntoVendita: parsed.puntoVendita ?? "",
  metodoPagamento: parsed.metodoPagamento ?? "",
  nota: notaPulita,
  idMacroarea: 0,

  origine: OrigineDati.ocr,

  // 🔥 SEARCH FIELDS
  searchCategoria: normalizeSmart(parsed.categoria ?? "Da scontrino"),
  searchDescrizione: normalizeSmart(parsed.descrizione ?? "Spesa rilevata da OCR"),
  searchPuntoVendita: normalizeSmart(parsed.puntoVendita ?? ""),
  searchMetodoPagamento: normalizeSmart(parsed.metodoPagamento ?? ""),

  // 🔥 DATA CREAZIONE (DateTime, verrà convertita da toMap)
  dataCreazione: DateTime.now(),
);


      // 6) Se completo → salva subito
      final completo = parsed.importo != null &&
          parsed.data != null &&
          parsed.categoria != null &&
          parsed.descrizione != null;

      if (completo) {
        await DatabaseHelper.instance.insertMovimento(nuovoMovimento);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Movimento salvato automaticamente")),
        );

        // 🔥 RITORNO IL MOVIMENTO ALLA PAGINA CHIAMANTE
        return nuovoMovimento;
      }

      // 7) Altrimenti apro la pagina di modifica
      final risultato = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DettaglioMovimentoPage(movimento: nuovoMovimento),
        ),
      );

      if (risultato is Movimento) {
        await DatabaseHelper.instance.insertMovimento(risultato);
        return risultato;
      }

      return null;

            } catch (e, stack) {
      // LOG COMPLETO DELL'ERRORE
      // ignore: avoid_print
      print('OCR ERROR: $e');
      // ignore: avoid_print
      print('OCR STACK: $stack');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore durante la scansione OCR")),
      );
      return null;
    }
  }
}