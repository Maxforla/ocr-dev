// ===============================================================
// OCR PARSER — VERSIONE COMPLETA, ROBUSTA E COMPATIBILE
// ===============================================================

import 'package:flutter/foundation.dart';
import '../data/vocabolario_prodotti.dart';

// ===============================================================
// RISULTATO OCR
// ===============================================================

class OcrResult {
  final String testoGrezzo;
  final String? puntoVendita;
  final String? categoria;
  final String? descrizione;
  final String? metodoPagamento;
  final double? importo;
  final DateTime? data;

  OcrResult({
    required this.testoGrezzo,
    this.puntoVendita,
    this.categoria,
    this.descrizione,
    this.metodoPagamento,
    this.importo,
    this.data,
  });
}

// ===============================================================
// PARSER PUBBLICO (CON ISOLATE)
// ===============================================================

class OcrParser {
  Future<OcrResult> parse(String raw) async {
    return compute(_parseSync, raw);
  }

  static OcrResult internalParseSync(String raw) {
    return _parseSync(raw);
  }

  static OcrResult _parseSync(String raw) {
    final parser = _OcrParserInternal();
    return parser.parse(raw);
  }
}

// ===============================================================
// PARSER INTERNO — VERSIONE FUZZY
// ===============================================================

class _OcrParserInternal {
  // -------------------------------------------------------------
  // ENTRY POINT
  // -------------------------------------------------------------
  OcrResult parse(String raw) {
    final normalized = _normalize(raw);
    final lines = _splitLines(normalized);

    final importo = _estraiTotale(lines);
    final metodo = _estraiMetodoPagamento(lines);
    final puntoVendita = _estraiPuntoVendita(lines);
    final data = _estraiData(lines);

    final categoriaDescrizione = _detectCategoriaEDescrizione(normalized);

    return OcrResult(
      testoGrezzo: raw,
      puntoVendita: puntoVendita,
      categoria: categoriaDescrizione['categoria'],
      descrizione: categoriaDescrizione['descrizione'],
      metodoPagamento: metodo,
      importo: importo,
      data: data,
    );
  }

  // -------------------------------------------------------------
  // NORMALIZZAZIONE
  // -------------------------------------------------------------
  String _normalize(String input) {
    return input
        .replaceAll('\r', '\n')
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim()
        .toLowerCase();
  }

  List<String> _splitLines(String t) {
    return t
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // -------------------------------------------------------------
  // IMPORTO TOTALE (FUZZY)
// -------------------------------------------------------------
  double? _estraiTotale(List<String> righe) {
    // 1) CERCA RIGHE "TOTALE COMPLESSIVO" (FUZZY) O "IMPORTO PAGATO"
    for (var i = righe.length - 1; i >= 0; i--) {
      final r = righe[i];
      if (_isRigaTotaleFuzzy(r) || _isRigaImportoPagato(r)) {
        final v = _estraiNumeroPlausibile(r);
        if (v != null) return v;
      }
    }

    // 2) FALLBACK: CERCA RIGHE CON "TOTALE" GENERICO
    for (var i = righe.length - 1; i >= 0; i--) {
      final r = righe[i];
      if (r.toLowerCase().contains('totale')) {
        final v = _estraiNumeroPlausibile(r);
        if (v != null) return v;
      }
    }

    // 3) FALLBACK FINALE: NUMERO PIÙ PLAUSIBILE NEL DOCUMENTO
    double? best;
    for (final r in righe) {
      final v = _estraiNumeroPlausibile(r);
      if (v != null) {
        if (best == null || v > best) best = v;
      }
    }

    return best;
  }

  bool _isRigaTotaleFuzzy(String riga) {
    final l = riga.toLowerCase();

    if (!l.contains('totale')) return false;

    // parole chiave "complessivo" con errori OCR tollerati
    const varianti = [
      'complessivo',
      'coyplessivo',
      'coplessivo',
      'complesivo',
      'complessiv0',
      'complesivo',
      'complessiv',
      'compless',
      'comp lessivo',
      'comp lessiv',
      'comp less',
    ];

    for (final v in varianti) {
      if (l.contains(v)) return true;
    }

    // se c'è "totale" e "comp" vicino, accettiamo comunque
    if (l.contains('totale') && l.contains('comp')) return true;

    return false;
  }

  bool _isRigaImportoPagato(String riga) {
    final l = riga.toLowerCase();
    return l.contains('importo pagato');
  }

  double? _estraiNumeroDaRiga(String riga) {
    final regex =
        RegExp(r'(\d{1,3}(\.\d{3})*|\d+)(,\d{2}|\.\d{2})?');
    final match =
        regex.allMatches(riga).map((m) => m.group(0)).whereType<String>().toList();
    if (match.isEmpty) return null;

    var raw = match.last;
    raw = raw.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(raw);
  }

  double? _estraiNumeroPlausibile(String riga) {
    final regex =
        RegExp(r'(\d{1,3}(\.\d{3})*|\d+)(,\d{2}|\.\d{2})?');
    final matches =
        regex.allMatches(riga).map((m) => m.group(0)).whereType<String>().toList();
    if (matches.isEmpty) return null;

    var raw = matches.last;

    if (raw.length > 10) return null;

    raw = raw.replaceAll('.', '').replaceAll(',', '.');

    final value = double.tryParse(raw);
    if (value == null) return null;

    if (value <= 0) return null;
    if (value > 9999) return null;
    if (!raw.contains('.')) return null;
    if (value < 0.10) return null;

    return value;
  }

  // -------------------------------------------------------------
  // METODO DI PAGAMENTO
  // -------------------------------------------------------------
  String? _estraiMetodoPagamento(List<String> righe) {
    final text = righe.join(' ').toLowerCase();

    if (text.contains('pagamento elettronico') ||
        text.contains('elettroni co') || // OCR storto
        text.contains('elettronico') ||
        text.contains('pos') ||
        text.contains('carta') ||
        text.contains('bancomat') ||
        text.contains('debito') ||
        text.contains('credito')) {
      return 'Pagamento elettronico';
    }

    if (text.contains('contanti') || text.contains('cash')) {
      return 'Contanti';
    }

    return null;
  }

  // -------------------------------------------------------------
  // PUNTO VENDITA
  // -------------------------------------------------------------
  String? _estraiPuntoVendita(List<String> righe) {
    final stopWords = [
      'documento commerciale',
      'di vendita',
      'prestazione',
      'scontrino',
      'appendice',
      'fattura',
    ];

    final candidate = <String>[];

    for (var i = 0; i < righe.length && i < 7; i++) {
      final r = righe[i];
      final lower = r.toLowerCase();
      if (stopWords.any((s) => lower.contains(s))) continue;
      if (r.length < 3) continue;
      candidate.add(r);
    }

    if (candidate.isEmpty) return null;

    return candidate.take(2).join(' ');
  }

  // -------------------------------------------------------------
  // DATA
  // -------------------------------------------------------------
  DateTime? _estraiData(List<String> righe) {
    final regex = RegExp(r'(\d{2})[-/](\d{2})[-/](\d{4})');

    for (final r in righe) {
      final m = regex.firstMatch(r);
      if (m != null) {
        final gg = int.tryParse(m.group(1)!);
        final mm = int.tryParse(m.group(2)!);
        final aa = int.tryParse(m.group(3)!);
        if (gg != null && mm != null && aa != null) {
          return DateTime(aa, mm, gg);
        }
      }
    }
    return null;
  }

  // -------------------------------------------------------------
  // CATEGORIA + DESCRIZIONE (compatibile con productMap)
  // -------------------------------------------------------------
  Map<String, String> _detectCategoriaEDescrizione(String text) {
    for (final key in productMap.keys) {
      if (text.contains(key.toLowerCase())) {
        return {
          'categoria': productMap[key]!['categoria']!,
          'descrizione': productMap[key]!['descrizione']!,
        };
      }
    }

    if (text.contains('bar') ||
        text.contains('caff') ||
        text.contains('ristorante') ||
        text.contains('pizzeria') ||
        text.contains('trattoria')) {
      return {
        'categoria': 'Ristorazione-Bar',
        'descrizione': 'Consumazione al bar',
      };
    }

    if (text.contains('farmacia') ||
        text.contains('parafarmacia') ||
        text.contains('sanitar')) {
      return {
        'categoria': 'Salute e Benessere',
        'descrizione': 'Farmacia',
      };
    }

    return {
      'categoria': 'Altro',
      'descrizione': 'Personalizza descrizione',
    };
  }
}