// ocr_flow.dart — FLUSSO OCR 2.1 (SAFE + C2 + FIX NAVIGAZIONE)

import 'package:flutter/material.dart';

import 'ocr_service.dart';
import 'ocr_parser.dart';

import '../models/movimento.dart';
import '../pages/dettaglio_movimento_page.dart';
import '../pages/ocr_loading_page.dart';

import '../utils/normalize_smart.dart';
import '../utils/database_helper.dart';

class OcrFlow {
  static Future<Movimento?> scan(BuildContext context) async {
    final ocr = OcrService();

    // ROUTE DELLA LOADING PAGE
    final loadingRoute = MaterialPageRoute(
      builder: (_) => const OcrLoadingPage(),
      fullscreenDialog: true,
    );

    try {
      // 1) Mostra loading
      Navigator.push(context, loadingRoute);

      // 2) Scatta foto
      final imageFile = await ocr.takePhoto();
      if (imageFile == null) {
        // Utente ha annullato
        return null;
      }

      // 3) OCR
      final rawText = await ocr.extractText(imageFile);

      // 4) Parsing sincrono
      final parsed = OcrParser.internalParseSync(rawText);

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

      // 7) Verifica completezza OCR
      final completo = parsed.importo != null &&
          parsed.categoria != null &&
          parsed.descrizione != null &&
          parsed.data != null;

      // ============================================================
      // 8) CASO A — OCR COMPLETO → tentativo di salvataggio SAFE
      // ============================================================

      if (completo) {
        final result =
            await DatabaseHelper.instance.insertMovimentoSafe(nuovoMovimento);

        // CHIUDI SEMPRE LA LOADING PAGE PRIMA DI APRIRE ALTRO
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Movimento salvato automaticamente")),
          );

          // Apri pagina di dettaglio
          final risultato = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DettaglioMovimentoPage(movimento: nuovoMovimento),
            ),
          );

          if (risultato is Movimento) {
            await DatabaseHelper.instance.insertMovimento(risultato);
            return risultato;
          }

          return nuovoMovimento;
        }

        // Categoria non esistente
        if (result.errorCode == "categoria_non_esistente") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Categoria non riconosciuta, personalizzare manualmente"),
            ),
          );

          final risultato = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DettaglioMovimentoPage(movimento: nuovoMovimento),
            ),
          );

          if (risultato is Movimento) {
            await DatabaseHelper.instance.insertMovimento(risultato);
            return risultato;
          }

          return null;
        }

        // Altri errori
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? "Errore OCR")),
        );

        return null;
      }

      // ============================================================
      // 9) CASO B — OCR INCOMPLETO → personalizzazione manuale
      // ============================================================

      // CHIUDI SEMPRE LA LOADING PAGE
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Movimento non salvato, personalizzare manualmente"),
        ),
      );

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
      print("OCR ERROR: $e");
      print("STACK: $stack");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore durante la scansione OCR")),
      );

      return null;
    } finally {
      // CHIUDI LA LOADING PAGE SE ANCORA APERTA
      if (Navigator.canPop(context) &&
          ModalRoute.of(context) == loadingRoute) {
        Navigator.pop(context);
      }
    }
  }
}