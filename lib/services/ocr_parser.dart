import '../database_helper.dart';

class OcrParsedData {
  final double? importo;
  final DateTime? data;
  final String? puntoVendita;
  final String? metodoPagamento;
  final String? categoria;
  final String? descrizione;
  final String testoGrezzo;

  OcrParsedData({
    required this.importo,
    required this.data,
    required this.puntoVendita,
    required this.metodoPagamento,
    required this.categoria,
    required this.descrizione,
    required this.testoGrezzo,
  });
}

class OcrParser {
  // MAPPA CATEGORIE / DESCRIZIONI
  final Map<String, Map<String, String>> _mappaCategorie = {
    // Svago / Bar
    "bar": {"categoria": "Svago", "descrizione": "Bar"},
    "caff": {"categoria": "Svago", "descrizione": "Bar"},
    "café": {"categoria": "Svago", "descrizione": "Bar"},
    "caffe": {"categoria": "Svago", "descrizione": "Bar"},
    "pasticc": {"categoria": "Svago", "descrizione": "Pasticceria / Bar"},
    "gelat": {"categoria": "Svago", "descrizione": "Gelateria"},

    // Ristoranti
    "ristorante": {"categoria": "Svago", "descrizione": "Ristorante"},
    "trattoria": {"categoria": "Svago", "descrizione": "Ristorante"},
    "pizzeria": {"categoria": "Svago", "descrizione": "Pizzeria"},
    "osteria": {"categoria": "Svago", "descrizione": "Ristorante"},
    "sushi": {"categoria": "Svago", "descrizione": "Ristorante"},
    "kebab": {"categoria": "Svago", "descrizione": "Ristorante"},
    "mcdonald": {"categoria": "Svago", "descrizione": "Fast food"},
    "mc donald": {"categoria": "Svago", "descrizione": "Fast food"},
    "burger king": {"categoria": "Svago", "descrizione": "Fast food"},
    "old wild west": {"categoria": "Svago", "descrizione": "Ristorante"},

    // Supermercati / Alimentari
    "supermercato": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "market": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "alimentari": {"categoria": "Alimentari", "descrizione": "Alimentari"},
    "coop": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "conad": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "carrefour": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "esselunga": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "md": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "lidl": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "eurospin": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "pam": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "despar": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "famila": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "iper": {"categoria": "Alimentari", "descrizione": "Ipermercato"},
    "ipercoop": {"categoria": "Alimentari", "descrizione": "Ipermercato"},
    "todis": {"categoria": "Alimentari", "descrizione": "Supermercato"},
    "simply": {"categoria": "Alimentari", "descrizione": "Supermercato"},

    // Farmacia
    "farmacia": {"categoria": "Salute", "descrizione": "Farmacia"},
    "parafarmacia": {"categoria": "Salute", "descrizione": "Farmacia"},

    // Tabacchi
    "tabac": {"categoria": "Tabacchi", "descrizione": "Tabacchi"},
    "tabacchi": {"categoria": "Tabacchi", "descrizione": "Tabacchi"},

    // Carburante
    "eni": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "q8": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "ip ": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "esso": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "tamoil": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "carburante": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "benzina": {"categoria": "Trasporti", "descrizione": "Carburante"},
    "diesel": {"categoria": "Trasporti", "descrizione": "Carburante"},

    // Tecnologia
    "mediaworld": {"categoria": "Tecnologia", "descrizione": "Elettronica"},
    "unieuro": {"categoria": "Tecnologia", "descrizione": "Elettronica"},
    "trony": {"categoria": "Tecnologia", "descrizione": "Elettronica"},
    "expert": {"categoria": "Tecnologia", "descrizione": "Elettronica"},
    "euronics": {"categoria": "Tecnologia", "descrizione": "Elettronica"},

    // Abbigliamento
    "zara": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "h&m": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "hm": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "ovs": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "calzedonia": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "intimissimi": {"categoria": "Abbigliamento", "descrizione": "Abbigliamento"},
    "scarpe": {"categoria": "Abbigliamento", "descrizione": "Calzature"},
  };


  // 1) APPRENDIMENTO DALLA CRONOLOGIA
  Future<Map<String, String>?> _categoriaDaCronologia(String? puntoVendita) async {
    if (puntoVendita == null || puntoVendita.isEmpty) return null;
    return await DatabaseHelper.instance
        .getCategoriaDescrizioneByPuntoVendita(puntoVendita);
  }

  // 2) PARSE COMPLETO
  Future<OcrParsedData> parse(String rawText) async {
    final righe = rawText.split("\n");

    final importo = _estraiTotale(righe);
    final data = _estraiData(rawText.toLowerCase());
    final puntoVendita = _estraiPuntoVendita(righe);
    final metodoPagamento = _estraiMetodoPagamento(righe);

    // 1) Prova dalla cronologia
    final storico = await _categoriaDaCronologia(puntoVendita);

    // 2) Se non c'è, usa parole chiave
    final catDesc = storico ?? _estraiCategoriaDescrizione(rawText, puntoVendita);

    return OcrParsedData(
      importo: importo != null ? double.tryParse(importo.toString()) : null,
      data: data,
      puntoVendita: puntoVendita != null
          ? DatabaseHelper.instance.normalizeSmart(puntoVendita)
          : null,
      metodoPagamento: metodoPagamento != null
          ? DatabaseHelper.instance.normalizeSmart(metodoPagamento)
          : null,
      categoria: DatabaseHelper.instance.normalizeSmart(
        _motoreCategoria3(rawText, puntoVendita)
      ),
      descrizione: DatabaseHelper.instance.normalizeSmart(
        _motoreDescrizione3(rawText, importo, data, puntoVendita)
      ),
      testoGrezzo: rawText.trim(),
    );

  }
  DateTime? _estraiData(String text) {
    final regex = RegExp(r'(\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4})');
    final match = regex.firstMatch(text);

    if (match != null) {
      final raw = match.group(1)!;

      // Normalizza separatori
      final normalized = raw.replaceAll(".", "/").replaceAll("-", "/");
      final parts = normalized.split("/");

      if (parts.length == 3) {
        final giorno = int.tryParse(parts[0]);
        final mese = int.tryParse(parts[1]);
        final anno = int.tryParse(
          parts[2].length == 2 ? "20${parts[2]}" : parts[2],
        );

        if (giorno != null && mese != null && anno != null) {
          return DateTime(anno, mese, giorno);
        }
      }
    }

    return null;
  }

  // 3) ESTRAZIONE TOTALE
  double? _estraiTotale(List<String> righe) {
    final paroleChiave = [
      "totale",
      "totale complessivo",
      "importo pagato",
      "da pagare",
      "totale euro",
      "totale documento",
      "totale finale",
    ];

    final normalizzate = righe.map((r) => r.toLowerCase()).toList();

    for (int i = 0; i < normalizzate.length; i++) {
      final riga = normalizzate[i];

      if (paroleChiave.any((k) => riga.contains(k))) {
        final numeroStessa = _estraiNumeroDaRiga(righe[i]);
        if (numeroStessa != null) return numeroStessa;

        if (i + 1 < righe.length) {
          final numeroSuccessiva = _estraiNumeroDaRiga(righe[i + 1]);
          if (numeroSuccessiva != null) return numeroSuccessiva;
        }
      }
    }

    // fallback: numero più alto
    final tutti = <double>[];
    for (final r in righe) {
      final n = _estraiNumeroDaRiga(r);
      if (n != null) tutti.add(n);
    }
    if (tutti.isNotEmpty) {
      return tutti.reduce((a, b) => a > b ? a : b);
    }

    return null;
  }

  double? _estraiNumeroDaRiga(String riga) {
    final regex = RegExp(r'(\d+[.,]\d{1,2})');
    final match = regex.firstMatch(riga);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(",", "."));
    }
    return null;
  }

  // 4) ESTRAZIONE PUNTO VENDITA
  String? _estraiPuntoVendita(List<String> righe) {
    final header = righe.take(6).toList();

    final keywords = [
      "bar",
      "caff",
      "café",
      "caffe",
      "ristorante",
      "pizzeria",
      "market",
      "minimarket",
      "drogheria",
      "macelleria",
      "supermercato",
      "tabac",
      "shop",
      "store",
      "alimentari",
      "farmacia",
      "parafarmacia",
    ];

    for (final r in header) {
      final lower = r.toLowerCase();
      if (keywords.any((k) => lower.contains(k))) {
        return DatabaseHelper.instance.normalizeSmart(r.trim());
      }
    }

    final pulite = header.where((r) {
      final l = r.toLowerCase();

      final contieneFarmacia = l.contains("farmacia") || l.contains("parafarmacia");

      return !l.contains("via") &&
          !l.contains("viale") &&
          !l.contains("piazza") &&
          !l.contains("p.iva") &&
          // consenti snc/srl/spa se è una farmacia
          (!l.contains("srl") || contieneFarmacia) &&
          (!l.contains("snc") || contieneFarmacia) &&
          (!l.contains("spa") || contieneFarmacia) &&
          r.trim().length > 3;
    }).toList();


    if (pulite.isNotEmpty) {
      return DatabaseHelper.instance.normalizeSmart(pulite.first.trim());
    }

    return null;
  }

  // 5) ESTRAZIONE METODO PAGAMENTO
  String? _estraiMetodoPagamento(List<String> righe) {
    final text = righe.join(" ").toLowerCase();

    final mappa = {
      // CONTANTI
      "contanti": "Contanti",
      "contante": "Contanti",
      "pagamento contante": "Contanti",
      "pagamento in contanti": "Contanti",
      "pagato contanti": "Contanti",
      "cash": "Contanti",
      "cash payment": "Contanti",

      // BANCOMAT / DEBITO
      "bancomat": "Bancomat",
      "pagamento bancomat": "Bancomat",
      "pagamento con bancomat": "Bancomat",
      "debito": "Bancomat",
      "carta di debito": "Bancomat",
      "maestro": "Bancomat",

      // CARTA DI CREDITO
      "carta": "Carta di credito",
      "carta di credito": "Carta di credito",
      "pagamento carta": "Carta di credito",
      "pagamento con carta": "Carta di credito",
      "mastercard": "Carta di credito",
      "visa": "Carta di credito",
      "american express": "Carta di credito",
      "amex": "Carta di credito",
      "credito": "Carta di credito",

      // POS / ELETTRONICO
      "pos": "Carta / Bancomat",
      "pagamento pos": "Carta / Bancomat",
      "pagamento elettronico": "Carta / Bancomat",
      "elettronico": "Carta / Bancomat",
      "pagamento digitale": "Carta / Bancomat",

      // SATISPAY
      "satispay": "Satispay",
      "pagamento satispay": "Satispay",

      // PAYPAL
      "paypal": "PayPal",
      "pagamento paypal": "PayPal",

      // APPLE PAY / GOOGLE PAY
      "apple pay": "Apple Pay",
      "pagamento apple pay": "Apple Pay",
      "google pay": "Google Pay",
      "pagamento google pay": "Google Pay",
    };


    for (final entry in mappa.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
  String _motoreCategoria3(String testo, String? puntoVendita) {
    final t = testo.toLowerCase();
    final pv = (puntoVendita ?? "").toLowerCase();

    final categorie = {
      "Alimentari": {
        "puntiVendita": ["conad", "coop", "lidl", "eurospin", "carrefour", "supermercato", "market", "iper"],
        "prodotti": ["pane", "pasta", "latte", "uova", "frutta", "verdura", "biscotti", "carne", "pesce"],
      },
      "Svago": {
        "puntiVendita": ["bar", "lounge bar", "caffetteria", "bistrot"],
        "prodotti": ["cappucc", "caff", "cornett", "brioche"],
      },
      "Ristorazione": {
        "puntiVendita": ["ristorante", "restaurant", "trattoria", "osteria", "pizzeria", "sushi", "kebab"],
        "prodotti": ["pizza", "primo", "secondo", "menu", "panino", "hamburger"],
      },
      "Salute": {
        "puntiVendita": ["farmacia", "parafarmacia"],
        "prodotti": ["tachipirina", "brufen", "aspirina", "farmaci", "paracetamolo"],
      },
      "Auto": {
        "puntiVendita": ["eni", "q8", "ip", "esso", "tamoil"],
        "prodotti": ["benzina", "diesel", "carburante"],
      },
      "Tecnologia": {
        "puntiVendita": ["mediaworld", "unieuro", "trony", "euronics"],
        "prodotti": ["cavo", "caricatore", "usb", "mouse", "tastiera"],
      },
      "Abbigliamento": {
        "puntiVendita": ["zara", "ovs", "h&m", "calzedonia"],
        "prodotti": ["maglia", "pantal", "scarpe", "felpa", "giacca"],
      },
    };

    // 1) Dal punto vendita
    for (final entry in categorie.entries) {
      for (final pvKey in entry.value["puntiVendita"]!) {
        if (pv.contains(pvKey)) return entry.key;
      }
    }

    // 2) Dal testo OCR
    for (final entry in categorie.entries) {
      for (final prodKey in entry.value["prodotti"]!) {
        if (t.contains(prodKey)) return entry.key;
      }
    }

    return "Altro";
  }

String _motoreDescrizione3(
  String testo,
  double? importo,
  DateTime? data,
  String? puntoVendita,
) {
  final t = testo.toLowerCase();
  final pv = (puntoVendita ?? "").toLowerCase();

  // --- 1) RICONOSCIMENTI SPECIALI 3.1 → 3.6 (già consolidati) ---

  // Caffè veloce
  if (t.contains("caff") && importo != null && importo <= 2.50) {
    return "Caffè veloce";
  }

  // Colazione salata
  if ((t.contains("toast") || t.contains("panino") || t.contains("uovo") || t.contains("salato")) &&
      data != null &&
      data.hour >= 7 &&
      data.hour <= 11) {
    return "Colazione salata al bar";
  }

  // Apericena
  if ((t.contains("spritz") || t.contains("cocktail") || t.contains("tagliere") || t.contains("aperitivo")) &&
      data != null &&
      data.hour >= 18 &&
      data.hour <= 21) {
    return "Apericena";
  }

  // Pranzo di lavoro
  if (data != null &&
      data.hour >= 12 &&
      data.hour <= 15 &&
      importo != null &&
      importo >= 10 &&
      importo <= 20 &&
      (pv.contains("ristorante") || pv.contains("restaurant"))) {
    return "Pranzo di lavoro";
  }

  // Take-away
  if (t.contains("take away") || t.contains("asporto") || t.contains("da asporto")) {
    return "Pasto da asporto";
  }

  // Spesa freschi
  if (t.contains("carne") || t.contains("pesce") || t.contains("frutta") || t.contains("verdura") || t.contains("latte")) {
    return "Spesa freschi";
  }

  // Spesa dispensa
  if (t.contains("pasta") || t.contains("biscotti") || t.contains("scatol") || t.contains("riso")) {
    return "Spesa dispensa";
  }

  // Colazione dolce
  if (t.contains("cornett") || t.contains("brioche") || t.contains("dolce")) {
    return "Colazione dolce";
  }

  // Bevande alcoliche
  if (t.contains("birra") || t.contains("vino") || t.contains("spritz") ||
      t.contains("cocktail") || t.contains("amaro")) {
    return "Bevande alcoliche";
  }

  // Bevande analcoliche
  if (t.contains("acqua") || t.contains("coca") || t.contains("fanta") ||
      t.contains("sprite") || t.contains("succo")) {
    return "Bevande analcoliche";
  }

  // Prodotti per animali
  if (t.contains("crocchette") || t.contains("scatolett") || t.contains("lettiera") ||
      t.contains("snack cane") || t.contains("snack gatto") || t.contains("gatto") || t.contains("cane")) {
    return "Prodotti per animali";
  }

  // Prodotti per la persona
  if (t.contains("shampoo") || t.contains("bagnoschiuma") || t.contains("sapone") ||
      t.contains("deodorante") || t.contains("dentifricio")) {
    return "Prodotti per la persona";
  }

  // Panetteria / Forno
  if (t.contains("pane") || t.contains("focaccia") || t.contains("taralli") ||
      t.contains("pizza al taglio") || t.contains("forno")) {
    return "Panetteria / Forno";
  }

  // Frutta e verdura
  if (t.contains("mela") || t.contains("banana") || t.contains("arancia") ||
      t.contains("insalata") || t.contains("zucchine") || t.contains("pomodoro") ||
      t.contains("ortaggi")) {
    return "Frutta e verdura";
  }

  // Carne e pesce
  if (t.contains("pollo") || t.contains("tacchino") || t.contains("manzo") ||
      t.contains("salmone") || t.contains("tonno") || t.contains("merluzzo") ||
      t.contains("macelleria") || t.contains("pescheria")) {
    return "Carne e pesce";
  }

  // Prodotti da frigo
  if (t.contains("yogurt") || t.contains("affettati") || t.contains("formagg") ||
      t.contains("burro") || t.contains("latte fresco")) {
    return "Prodotti da frigo";
  }

  // Prodotti surgelati
  if (t.contains("surgelat") || t.contains("gelat") || t.contains("verdure surgelate") ||
      t.contains("pesce surgelato")) {
    return "Prodotti surgelati";
  }

  // Prodotti per la casa avanzati
  if (t.contains("anticalcare") || t.contains("ammorbidente") || t.contains("detergente") ||
      t.contains("wc") || t.contains("candeggina") || t.contains("sgrassatore")) {
    return "Prodotti per la casa";
  }

  // Cura persona avanzata
  if (t.contains("crema") || t.contains("lozione") || t.contains("balsamo") ||
      t.contains("barba") || t.contains("igiene intima")) {
    return "Cura della persona";
  }

  // Prodotti per bambini
  if (t.contains("pannolin") || t.contains("salviett") || t.contains("latte in polvere") ||
      t.contains("omogeneizz") || t.contains("prima infanzia")) {
    return "Prodotti per bambini";
  }

  // Prodotti per animali avanzati
  if (t.contains("antiparassit") || t.contains("shampoo cane") || t.contains("shampoo gatto") ||
      t.contains("tiragraffi") || t.contains("guinzaglio") || t.contains("gioco cane") || t.contains("gioco gatto")) {
    return "Prodotti per animali";
  }

  // Prodotti per ufficio
  if (t.contains("carta a4") || t.contains("toner") || t.contains("cartucc") ||
      t.contains("penne") || t.contains("quaderno") || t.contains("raccoglitore")) {
    return "Prodotti per ufficio";
  }

  // Prodotti per auto
  if (t.contains("olio motore") || t.contains("tergicristalli") || t.contains("lampadine auto") ||
      t.contains("deodorante auto") || t.contains("accessori auto")) {
    return "Prodotti per auto";
  }

  // Giardinaggio
  if (t.contains("terriccio") || t.contains("vasi") || t.contains("sementi") ||
      t.contains("fertilizzante") || t.contains("attrezzi giardino")) {
    return "Giardinaggio";
  }

  // Pulizie professionali
  if (t.contains("haccp") || t.contains("industriale") || t.contains("professionale") ||
      t.contains("disinfettante forte")) {
    return "Pulizie professionali";
  }

  // --- 2) RICONOSCIMENTI AVANZATI 3.7 ---

  // Ristorazione internazionale
  if (t.contains("sushi") || t.contains("sashimi") || t.contains("ramen") ||
      t.contains("udon") || t.contains("poke") || t.contains("kebab") ||
      t.contains("tikka") || t.contains("masala") || t.contains("naan") ||
      t.contains("tacos") || t.contains("burrito") || t.contains("nachos") ||
      t.contains("gyros") || t.contains("pita")) {
    return "Ristorazione internazionale";
  }

  // Pasticceria avanzata
  if (t.contains("cannolo") || t.contains("cannoli") || t.contains("babà") ||
      t.contains("sfogliatella") || t.contains("mignon") || t.contains("torta") ||
      t.contains("crostat") || t.contains("pasticceria")) {
    return "Pasticceria";
  }

  // Supermercato premium
  if (t.contains("dop") || t.contains("igp") || t.contains("doc") || t.contains("docg") ||
      t.contains("gourmet") || t.contains("artigianale") || t.contains("premium") ||
      t.contains("alta qualità")) {
    return "Prodotti premium";
  }

  // Elettronica avanzata
  if (t.contains("smart home") || t.contains("domotica") || t.contains("lampadina smart") ||
      t.contains("presa smart") || t.contains("sensore") || t.contains("power bank") ||
      t.contains("bluetooth") || t.contains("tech")) {
    return "Elettronica avanzata";
  }

  // --- 3) CATEGORIA BASE (3.0) ---
  final categoria = _motoreCategoria3(testo, puntoVendita);

  switch (categoria) {
    case "Svago":
      if (t.contains("cappucc") || t.contains("cornett") || t.contains("brioche")) {
        return "Colazione al bar";
      }
      if (t.contains("caff")) return "Caffè al bar";
      if (data != null && data.hour >= 17 && data.hour <= 20) return "Aperitivo";
      return "Bar";

    case "Ristorazione":
      if (data != null && data.hour >= 18) return "Cena al ristorante";
      if (data != null && data.hour >= 12) return "Pranzo al ristorante";
      return "Pasto al ristorante";

    case "Salute":
      return "Farmaci";

    case "Auto":
      return "Rifornimento carburante";

    case "Alimentari":
      if (importo != null) {
        if (importo < 15) return "Spesa piccola";
        if (importo < 50) return "Spesa media";
        return "Spesa grande";
      }
      return "Spesa alimentare";

    case "Tecnologia":
      return "Elettronica – Accessori";

    case "Abbigliamento":
      return "Abbigliamento";

    default:
      return "Acquisto";
  }
}




  // 6) ESTRAZIONE CATEGORIA + DESCRIZIONE
  Map<String, String>? _estraiCategoriaDescrizione(String testo, String? puntoVendita) {
    final lowerText = testo.toLowerCase();
    final lowerPdV = puntoVendita?.toLowerCase() ?? "";

    for (final key in _mappaCategorie.keys) {
      if (lowerPdV.contains(key)) {
        return _mappaCategorie[key];
      }
    }

    for (final key in _mappaCategorie.keys) {
      if (lowerText.contains(key)) {
        return _mappaCategorie[key];
      }
    }

    return null;
  }

  // 7) PULIZIA NOTA OCR
  String pulisciNotaOCR(String testo) {
    final righe = testo.split('\n');

    String? intestazione;
    String? numeroDocumento;
    String? dataDocumento;
    String? totale;

    for (var r in righe) {
      final line = r.trim();

      // Intestazione PdV
      if (intestazione == null &&
          line.isNotEmpty &&
          !RegExp(r'[0-9]').hasMatch(line) &&
          line.length > 3) {
        intestazione = line;
      }

      // Numero documento
      final docMatch = RegExp(
        r'(documento|doc\.?|fattura)\s*(n\.?|numero)?\s*([0-9]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (docMatch != null) {
        numeroDocumento = "Documento n. ${docMatch.group(3)}";
      }

      // Data documento
      final dataMatch = RegExp(
        r'(\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4})',
      ).firstMatch(line);
      if (dataMatch != null) {
        dataDocumento = "Data: ${dataMatch.group(1)}";
      }

      // Totale
      final totMatch = RegExp(
        r'(totale|importo)\s*[: ]\s*([0-9]+[.,][0-9]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (totMatch != null) {
        totale = "Totale: €${totMatch.group(2)}";
      }
    }

    final buffer = <String>[];
    if (intestazione != null) buffer.add(intestazione!);
    if (numeroDocumento != null) buffer.add(numeroDocumento!);
    if (dataDocumento != null) buffer.add(dataDocumento!);
    if (totale != null) buffer.add(totale!);

    return buffer.join('\n');
  }
}