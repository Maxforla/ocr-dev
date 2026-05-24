import 'package:spese_app/utils/database_helper.dart';

class CategoriaService {
  /// Motore categoria centralizzato e intelligente.
  /// Ordine di priorità:
  /// 1) Cronologia (apprendimento)
  /// 2) Punto vendita
  /// 3) Articoli (quando disponibili)
  /// 4) Importo
  /// 5) Fallback
  static Future<String> inferisciCategoria({
    required String testo,
    required String? puntoVendita,
    required double? importo,
  }) async {
    final t = testo.toLowerCase();
    final pv = (puntoVendita ?? "").toLowerCase();

    // ============================================================
    // 1) CRONOLOGIA — PRIORITÀ ASSOLUTA
    // ============================================================
    final storico = await DatabaseHelper.instance
        .getCategoriaDescrizioneByPuntoVendita(puntoVendita ?? "");
    if (storico != null && storico["categoria"] != null) {
      return storico["categoria"]!;
    }

// 1.5) ARTICOLI — se presenti, hanno priorità alta
if (testo.contains("cornetto") ||
    testo.contains("cappuccino") ||
    testo.contains("pasticciotto") ||
    testo.contains("brioche")) {
  return "Svago";
}

if (testo.contains("pane") ||
    testo.contains("latte") ||
    testo.contains("yogurt") ||
    testo.contains("pomodori") ||
    testo.contains("insalata")) {
  return "Alimentari";
}

if (testo.contains("tachipirina") ||
    testo.contains("paracetamolo") ||
    testo.contains("farmaci")) {
  return "Salute";
}

if (testo.contains("benzina") ||
    testo.contains("diesel") ||
    testo.contains("carburante")) {
  return "Auto";
}


    // ============================================================
    // 2) PUNTO VENDITA — BAR / CAFFETTERIA / PASTICCERIA
    // ============================================================
    final barKeywords = [
      "bar", "caff", "caffè", "cafe", "cafè", "pasticc", "bistrot",
      "lounge", "pretoria", "coffee", "bakery"
    ];
    if (barKeywords.any((k) => pv.contains(k))) {
      return "Svago";
    }

    // ============================================================
    // 3) PUNTO VENDITA — SUPERMERCATI / ALIMENTARI
    // ============================================================
    final marketKeywords = [
      "conad", "coop", "lidl", "eurospin", "carrefour", "market",
      "supermercato", "despar", "pam", "md", "todis"
    ];
    if (marketKeywords.any((k) => pv.contains(k))) {
      return "Alimentari";
    }

    // ============================================================
    // 4) PUNTO VENDITA — RISTORANTI
    // ============================================================
    final ristoKeywords = [
      "pizzeria", "ristorante", "trattoria", "osteria",
      "sushi", "kebab", "mcdonald", "burger king"
    ];
    if (ristoKeywords.any((k) => pv.contains(k))) {
      return "Svago";
    }

    // ============================================================
    // 5) PUNTO VENDITA — FARMACIA
    // ============================================================
    if (pv.contains("farmacia") || pv.contains("parafarmacia")) {
      return "Salute";
    }

    // ============================================================
    // 6) PUNTO VENDITA — CARBURANTE
    // ============================================================
    final fuelKeywords = ["eni", "q8", "ip ", "esso", "tamoil"];
    if (fuelKeywords.any((k) => pv.contains(k))) {
      return "Auto";
    }

    // ============================================================
    // 7) PUNTO VENDITA — TECNOLOGIA
    // ============================================================
    final techKeywords = ["mediaworld", "unieuro", "trony", "euronics"];
    if (techKeywords.any((k) => pv.contains(k))) {
      return "Tecnologia";
    }

    // ============================================================
    // 8) PUNTO VENDITA — ABBIGLIAMENTO
    // ============================================================
    final fashionKeywords = ["zara", "ovs", "h&m", "calzedonia"];
    if (fashionKeywords.any((k) => pv.contains(k))) {
      return "Abbigliamento";
    }

    // ============================================================
    // 9) IMPORTO — BAR (salvagente intelligente)
    // ============================================================
    if (importo != null && importo < 6) {
      return "Svago";
    }

    // ============================================================
    // 10) FALLBACK
    // ============================================================
    return "Altro";
  }
}