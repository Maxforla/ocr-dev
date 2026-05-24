import 'package:flutter/foundation.dart';
import '../data/vocabolario_prodotti.dart';
import '../vocabolari.dart';

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

class OcrParser {
  // ============================================================
  // ENTRY POINT ASINCRONO (usato fuori dagli isolate)
  // ============================================================
  Future<OcrResult> parse(String raw) async {
    return compute(_parseSync, raw);
  }

  // ============================================================
  // WRAPPER PUBBLICO PER GLI ISOLATE
  // ============================================================
  static OcrResult internalParseSync(String raw) {
    return _parseSync(raw);
  }

  // ============================================================
  // PARSER SINCRONO (usato da compute e dagli isolate)
  // ============================================================
  static OcrResult _parseSync(String raw) {
    final parser = _OcrParserInternal();
    return parser.parse(raw);
  }
}

class _OcrParserInternal {
  // ============================================================
  // FUNZIONE PRINCIPALE
  // ============================================================
  OcrResult parse(String raw) {
    final text = raw.toLowerCase();
    final lines = _splitLines(raw);

    // 1) TENTATIVO PRINCIPALE: PRODOTTI
    final productMatch = _detectProduct(text);
    if (productMatch != null) {
      return _buildResult(
        raw,
        lines,
        categoria: productMatch['categoria']!,
        descrizione: productMatch['descrizione']!,
      );
    }

    // 2) FALLBACK: categorie base (ristorante, farmacia, ecc.)
    final fallback = _detectFallbackCategory(text);
    if (fallback != null) {
      return _buildResult(
        raw,
        lines,
        categoria: fallback['categoria']!,
        descrizione: fallback['descrizione']!,
      );
    }

    // 3) FALLBACK FINALE
    return _buildResult(
      raw,
      lines,
      categoria: 'Altro',
      descrizione: 'Personalizza descrizione',
    );
  }

  // ============================================================
  // CERCA IL PRIMO PRODOTTO NEL TESTO (P1)
  // ============================================================
  Map<String, String>? _detectProduct(String text) {
  // Ignora "acqua" se è nella prima riga (nome negozio)
  final firstLine = text.split('\n').first.trim();
  final ignoreAcqua = firstLine.contains('acqua');

  for (final key in productMap.keys) {
    if (ignoreAcqua && key == 'acqua') continue;

    if (text.contains(key)) {
      return productMap[key];
    }
  }
  return null;
}


  // ============================================================
  // FALLBACK CATEGORIE BASE (ristorante, farmacia, ecc.)
  // ============================================================
  Map<String, String>? _detectFallbackCategory(String text) {
    // RISTORAZIONE
    if (text.contains('ristorante') ||
        text.contains('pizzeria') ||
        text.contains('trattoria') ||
        text.contains('bar') ||
        text.contains('caff')) {
      return {
        'categoria': 'Ristorazione',
        'descrizione': 'Ristorante'
      };
    }

    // SALUTE
    if (text.contains('farmacia') ||
        text.contains('parafarmacia') ||
        text.contains('sanitar')) {
      return {
        'categoria': 'Salute e Benessere',
        'descrizione': 'Farmacia'
      };
    }

    return null;
  }

  // ============================================================
  // COSTRUZIONE RISULTATO
  // ============================================================
  OcrResult _buildResult(
    String raw,
    List<String> lines, {
    required String categoria,
    required String descrizione,
  }) {
    return OcrResult(
      testoGrezzo: raw,
      puntoVendita: _extractPuntoVendita(lines),
      categoria: categoria,
      descrizione: descrizione,
      metodoPagamento: _extractMetodoPagamento(lines),
      importo: _extractImporto(lines),
      data: _extractData(raw),
    );
  }

  // ============================================================
  // ESTRAZIONE IMPORTO
  // ============================================================
  double? _extractImporto(List<String> lines) {
    final regex = RegExp(r'(\d{1,4}[.,]\d{2})');

    for (final line in lines.reversed) {
      final match = regex.firstMatch(line);
      if (match != null) {
        return double.tryParse(
          match.group(1)!.replaceAll('.', '').replaceAll(',', '.'),
        );
      }
    }
    return null;
  }

  // ============================================================
  // ESTRAZIONE METODO DI PAGAMENTO
  // ============================================================
  String _extractMetodoPagamento(List<String> lines) {
  final text = lines.join(' ').toLowerCase();

  if (text.contains('pagamento contante') ||
      text.contains('pagamento in contante') ||
      text.contains('pagamento contanti') ||
      text.contains('pagamento cont.') ||
      text.contains('contante')) {
    return 'Contanti';
  }

  if (text.contains('pagamento elettronico') ||
      text.contains('elettronico') ||
      text.contains('pos')) {
    return 'POS / Pagamento elettronico';
  }

  if (text.contains('bancomat')) return 'Bancomat / Debito';
  if (text.contains('carta')) return 'Carta di debito';

  return 'Altro';
}

  // ============================================================
  // ESTRAZIONE PUNTO VENDITA
  // ============================================================
  String _extractPuntoVendita(List<String> lines) {
    if (lines.isEmpty) return 'Punto vendita non rilevato';

    final first = lines[0];
    if (lines.length == 1) return first;

    final second = lines[1].toLowerCase();
    final isAddress = second.startsWith('via') ||
        second.startsWith('viale') ||
        second.startsWith('corso') ||
        second.startsWith('piazza');

    if (isAddress) return first;

    return '$first – ${lines[1]}';
  }

  // ============================================================
  // ESTRAZIONE DATA
  // ============================================================
  DateTime? _extractData(String raw) {
    final regex = RegExp(r'(\d{2})[\/\-](\d{2})[\/\-](\d{4})');
    final match = regex.firstMatch(raw);
    if (match == null) return null;

    try {
      final giorno = int.parse(match.group(1)!);
      final mese = int.parse(match.group(2)!);
      final anno = int.parse(match.group(3)!);
      return DateTime(anno, mese, giorno);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================
  List<String> _splitLines(String t) {
    return t
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}