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
  // =====================
// DIZIONARIO PRODOTTI
// =====================
final Map<String, Map<String, String>> _prodotti = {
  // Latticini
  "mozzarella": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "fior di latte": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "scamorza": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "provola": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "ricotta": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "burro": {"categoria": "Alimentari", "descrizione": "Latticini"},
  "yogurt": {"categoria": "Alimentari", "descrizione": "Prodotti da frigo"},
  "latte": {"categoria": "Alimentari", "descrizione": "Prodotti da frigo"},

  // Pane e forno
  "pane": {"categoria": "Alimentari", "descrizione": "Panetteria / Forno"},
  "panino": {"categoria": "Alimentari", "descrizione": "Panetteria / Forno"},
  "baguette": {"categoria": "Alimentari", "descrizione": "Panetteria / Forno"},
  "cornetto": {"categoria": "Alimentari", "descrizione": "Pasticceria"},
  "brioche": {"categoria": "Alimentari", "descrizione": "Pasticceria"},
  "pizza": {"categoria": "Alimentari", "descrizione": "Panetteria / Forno"},

  // Carne
  "pollo": {"categoria": "Alimentari", "descrizione": "Carne"},
  "bistecca": {"categoria": "Alimentari", "descrizione": "Carne"},
  "macinato": {"categoria": "Alimentari", "descrizione": "Carne"},
  "salsiccia": {"categoria": "Alimentari", "descrizione": "Carne"},

  // Pesce
  "pesce": {"categoria": "Alimentari", "descrizione": "Pesce"},
  "merluzzo": {"categoria": "Alimentari", "descrizione": "Pesce"},
  "salmone": {"categoria": "Alimentari", "descrizione": "Pesce"},

  // Frutta
  "mele": {"categoria": "Alimentari", "descrizione": "Frutta"},
  "banane": {"categoria": "Alimentari", "descrizione": "Frutta"},
  "arance": {"categoria": "Alimentari", "descrizione": "Frutta"},
  "fragole": {"categoria": "Alimentari", "descrizione": "Frutta"},

  // Verdura
  "insalata": {"categoria": "Alimentari", "descrizione": "Verdura"},
  "pomodori": {"categoria": "Alimentari", "descrizione": "Verdura"},
  "zucchine": {"categoria": "Alimentari", "descrizione": "Verdura"},
  "patate": {"categoria": "Alimentari", "descrizione": "Verdura"},

  // Casa
  "detersivo": {"categoria": "Casa", "descrizione": "Prodotti per la casa"},
  "sapone": {"categoria": "Casa", "descrizione": "Prodotti per la persona"},
  "spugna": {"categoria": "Casa", "descrizione": "Prodotti per la casa"},

  // Animali
  "crocchette": {"categoria": "Animali", "descrizione": "Cibo per animali"},
  "lettiera": {"categoria": "Animali", "descrizione": "Prodotti per animali"},
};

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
    // 1) Ricostruisci le righe da MLKit
final blocchi = rawText
    .replaceAll(RegExp(r' {2,}'), '\n')   // doppio spazio = nuova riga
    .replaceAll(RegExp(r'(?<=[a-z]) (?=[A-Z])'), '\n') // minuscola + spazio + maiuscola
    .replaceAll(RegExp(r'(?<=[0-9]) (?=[A-Z])'), '\n') // numero + spazio + maiuscola
    .replaceAll(RegExp(r'(?<=[a-z]) (?=[0-9])'), '\n') // minuscola + spazio + numero
    .split('\n')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

// 2) Applica le correzioni OCR su ogni riga
final righe = blocchi.map((r) => _correggiErroriOCR(r)).toList();

// 3) Ricostruisci il testo corretto
rawText = righe.join("\n");

// 3b) Ricalcola le righe corrette
final righeCorrette = rawText.split("\n");

// 🔍 DEBUG: stampa le righe corrette
print("=== RIGHE CORRETTE ===");
for (final r in righeCorrette) print(r);
print("=======================");

// 4) Estrazioni basate sulle righe corrette
final importo = _estraiTotale(righeCorrette);
final data = _estraiData(rawText.toLowerCase());
final puntoVendita = _estraiPuntoVendita(righeCorrette);
final metodoPagamento = _estraiMetodoPagamento(righeCorrette);
final metodoStorico = await _metodoDaCronologia(puntoVendita);
final metodoFinale = metodoPagamento ?? metodoStorico;
print("Metodo OCR: $metodoPagamento | Metodo storico: $metodoStorico | Metodo finale: $metodoFinale");


    return OcrParsedData(
      importo: importo,
      data: data,
      puntoVendita: puntoVendita != null
          ? DatabaseHelper.instance.normalizeSmart(puntoVendita)
          : null,
      metodoPagamento: metodoFinale != null
    ? DatabaseHelper.instance.normalizeSmart(metodoFinale)
    : null,

      categoria: DatabaseHelper.instance.normalizeSmart(
  _motoreCategoria4(rawText, puntoVendita)
),
      descrizione: DatabaseHelper.instance.normalizeSmart(
  _motoreDescrizione5(rawText, importo, data, puntoVendita)
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
// ---------------------------------------------------------
// 3) ESTRAZIONE PUNTO VENDITA
// ---------------------------------------------------------
String? _estraiPuntoVendita(List<String> righe) {
  // ---------------------------------------------------------
  // 3.1) PRELIEVO HEADER (prime 10 righe dello scontrino)
  // ---------------------------------------------------------
  final header = righe.take(10).toList();

  // ---------------------------------------------------------
  // 3.2) RICOSTRUZIONE INTELLIGENTE DEL PdV SPEZZATO
  // ---------------------------------------------------------
  final bloccoPdV = <String>[];

  for (final r in header) {
    final lower = r.toLowerCase();

    // Cerca tutte le parti del PdV (caseificio, lioi, sas, ecc.)
    if (lower.contains("case") ||
        lower.contains("ficio") ||
        lower.contains("lioi") ||
        lower.contains("sas")) {
      bloccoPdV.add(r.trim());
    }
  }

  // Se abbiamo almeno 2 righe → uniamo e puliamo
  if (bloccoPdV.length >= 2) {
    final unito = bloccoPdV.join(" ");
    return _pulisciPuntoVendita(unito);
  }

  // ---------------------------------------------------------
  // 3.3) FALLBACK: PRIMA RIGA NON INDIRIZZO
  // ---------------------------------------------------------
  for (final r in header) {
    final lower = r.toLowerCase();

    final eIndirizzo =
        lower.startsWith("via") ||
        lower.startsWith("viale") ||
        lower.startsWith("piazza");

    if (!eIndirizzo && r.trim().length > 3) {
      return _pulisciPuntoVendita(r);
    }
  }

  // Nessun PdV trovato
  return null;
}
// ---------------------------------------------------------
// PULIZIA PUNTO VENDITA
// ---------------------------------------------------------
String _pulisciPuntoVendita(String s) {
  var testo = s.trim();
  final lower = testo.toLowerCase();

  // Caso speciale: NON tagliare mai Caseificio Lioi
  if (lower.contains("caseificio") || lower.contains("lioi")) {
    return testo;
  }

  final stopWords = [
    ' p. iva',
    ' partita iva',
    ' documento',
    ' descrizione',
    ' totale',
    ' rt ',
    ' reg. ',
  ];

  var cutIndex = testo.length;

  for (final w in stopWords) {
    final i = lower.indexOf(w);
    if (i >= 0 && i < cutIndex) {
      cutIndex = i;
    }
  }

  testo = testo.substring(0, cutIndex);
  testo = testo.split(',').first;

  final words = testo.split(' ').where((w) => w.trim().isNotEmpty).toList();
  if (words.length > 4) {
    testo = words.take(4).join(' ');
  }

  return testo.trim();
}



  // 3) ESTRAZIONE TOTALE
  double? _estraiTotale(List<String> righe) {
  final paroleChiave = [
    "totale complessivo",
    "importo pagato",
    "totale documento",
    "totale finale",
    "totale euro",
    "totale",
    "da pagare",
  ];

  // 🔹 Caso speciale robusto: IMPORTO PAGATO seguito da un numero
  for (int i = 0; i < righe.length; i++) {
    final riga = righe[i].toLowerCase();

    if (riga.contains("importo pagato")) {
      // cerca nelle 3 righe successive
      for (int j = 1; j <= 3; j++) {
        if (i + j < righe.length) {
          final n = _estraiNumeroDaRiga(righe[i + j]);
          if (n != null) return n;
        }
      }
    }
  }

  // 🔹 Caso speciale robusto: TOTALE COMPLESSIVO seguito da un numero
  for (int i = 0; i < righe.length; i++) {
    final riga = righe[i].toLowerCase();

    if (riga.contains("totale complessivo")) {
      // cerca nelle 3 righe successive
      for (int j = 1; j <= 3; j++) {
        if (i + j < righe.length) {
          final n = _estraiNumeroDaRiga(righe[i + j]);
          if (n != null) return n;
        }
      }
    }
  }


  final normalizzate = righe.map((r) => r.toLowerCase()).toList();

  for (int i = 0; i < normalizzate.length; i++) {
    final riga = normalizzate[i];

    // 🔹 Filtro anti-IVA
    if (riga.contains("iva") && !riga.contains("totale complessivo")) {
      continue;
    }

    // 🔹 Filtro anti-prezzo unitario
    if (riga.contains("prezzo")) {
      continue;
    }

    if (paroleChiave.any((k) => riga.contains(k))) {
      final numeroStessa = _estraiNumeroDaRiga(righe[i]);
      if (numeroStessa != null) return numeroStessa;

      if (i + 1 < righe.length) {
        final numeroSuccessiva = _estraiNumeroDaRiga(righe[i + 1]);
        if (numeroSuccessiva != null) return numeroSuccessiva;
      }
    }
  }

  // 🔹 Fallback: prendi solo numeri plausibili (1–500 €)
  // 🔹 Fallback: ignora righe con IVA o percentuali
final tutti = <double>[];
for (final r in righe) {
  final lower = r.toLowerCase();

  // salta righe che parlano di IVA o hanno il simbolo %
  if (lower.contains("iva") || lower.contains("%")) {
    continue;
  }

  final n = _estraiNumeroDaRiga(r);
  if (n != null) tutti.add(n);
}

final plausibili = tutti.where((n) => n >= 1 && n <= 500).toList();
if (plausibili.isNotEmpty) {
  return plausibili.reduce((a, b) => a > b ? a : b);
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


Future<String?> _metodoDaCronologia(String? puntoVendita) async {
  if (puntoVendita == null || puntoVendita.isEmpty) return null;
  return await DatabaseHelper.instance
      .getMetodoPagamentoByPuntoVendita(puntoVendita);
}






//ESTRAI METODO_DI_PAGAMENTO===============================
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
    "pagamentoelettronico": "Carta / Bancomat",
    "pagamento elettron": "Carta / Bancomat",
    "pagamento elettr": "Carta / Bancomat",
    "elettronico": "Carta / Bancomat",
    "elettr": "Carta / Bancomat",
    "pagamento digitale": "Carta / Bancomat",

    // PAGATO CON
    "pagato con": "Carta / Bancomat",

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

  // 1️⃣ Matching diretto
  for (final entry in mappa.entries) {
    if (text.contains(entry.key)) {
      return entry.value;
    }
  }

  // 2️⃣ Riconoscimento intelligente
  if (text.contains("pagamento") && text.contains("elettr")) {
    return "Carta / Bancomat";
  }

  // 3️⃣ Fallback RT (scontrino elettronico)
  if (text.contains("rt ")) {
    return "Carta / Bancomat";
  }

  // 4️⃣ Fallback DOC (quasi sempre elettronico)
  if (text.contains("doc.") && !text.contains("contanti")) {
    return "Carta / Bancomat";
  }

  // 5️⃣ Fuzzy matching (ULTIMA SPIAGGIA)
  final dizionario = mappa.keys.toList();
  final parole = text.split(" ");

  for (final p in parole) {
    final match = _fuzzyMatch(p, dizionario, soglia: 2);
    if (match != p && mappa.containsKey(match)) {
      return mappa[match];
    }
  }

  return null;
}


/// CORREGGI ERRORI OCR ==========================================
String _correggiErroriOCR(String t) {
  // Porta tutto in minuscolo per sostituzioni robuste
  var s = t.toLowerCase();

  // --- Normalizzazione spazi ---
  s = s.replaceAll(RegExp(r'[ ]{2,}'), ' ');
  s = s.replaceAll(RegExp(r'\n\s+'), '\n');

  // --- Correzioni parole comuni OCR ---
  final sostituzioni = {
    // ---------------------------------------------------------
    // GENERICHE
    // ---------------------------------------------------------
    "c/so": "corso",
    "c.so": "corso",
    "garibaldl": "garibaldi",
    "doc n": "documento n.",
    "importo pagato": "importo pagato",
    "caffe'": "caffè",
    "caffe": "caffè",

    // ---------------------------------------------------------
    // PAGAMENTO — varianti OCR
    // ---------------------------------------------------------
    "pagame nt0": "pagamento",
    "pagament0": "pagamento",
    "pagame nto": "pagamento",
    "pagam ento": "pagamento",
    "pagam": "pagamento",

    // ---------------------------------------------------------
    // ELETTRONICO — varianti OCR
    // ---------------------------------------------------------
    "ele11r0n1c0": "elettronico",
    "ele1tr0n1co": "elettronico",
    "elett r0n1co": "elettronico",
    "elettro nico": "elettronico",
    "ele": "elettronico",

    // ---------------------------------------------------------
    // CASEIFICIO — varianti OCR reali
    // ---------------------------------------------------------
    "case1f1cio": "caseificio",
    "case1f 1cio": "caseificio",
    "case1ficio": "caseificio",
    "case1f 1c10": "caseificio",
    "case1f1c10": "caseificio",
    "1c10": "ficio",
    "1c1o": "ficio",

    // ---------------------------------------------------------
    // LIOI — varianti OCR reali
    // ---------------------------------------------------------
    "l101": "lioi",
    "lio1": "lioi",
    "liot": "lioi",
    "li0i": "lioi",

    // ---------------------------------------------------------
    // INDIRIZZO
    // ---------------------------------------------------------
    "v1a": "via",

    // ---------------------------------------------------------
    // TOTALE / IMPORTO
    // ---------------------------------------------------------
    "iotale": "totale",
    "conpl essi0": "complessivo",
    "inporto": "importo",
    "1va": "iva",

    // ---------------------------------------------------------
    // PREZZO
    // ---------------------------------------------------------
    "prezzo1€": "prezzo (€)",
    "prezzo1€)": "prezzo (€)",

    // ---------------------------------------------------------
    // PAROLE UTILI PER CATEGORIA / DESCRIZIONE
    // ---------------------------------------------------------
    "mozzarella": "mozzarella",
  };

  // Applica tutte le sostituzioni
  sostituzioni.forEach((k, v) {
    s = s.replaceAll(k, v);
  });

  return s.trim();
}


// ---------------------------------------------------------
// FUZZY MATCHING (basato su distanza di Levenshtein)
// ---------------------------------------------------------
// Ritorna la voce del dizionario più simile all'input,
// solo se la distanza è <= soglia. Altrimenti ritorna l'input stesso.
String _fuzzyMatch(String input, List<String> dizionario, {int soglia = 3}) {
  final query = input.toLowerCase().trim();

  String migliore = query;
  int distanzaMigliore = 999;

  for (final voce in dizionario) {
    final voceNorm = voce.toLowerCase();
    final distanza = _levenshtein(query, voceNorm);

    if (distanza < distanzaMigliore && distanza <= soglia) {
      distanzaMigliore = distanza;
      migliore = voce;
    }
  }

  return migliore;
}


// ---------------------------------------------------------
// RICONOSCIMENTO PRODOTTI (match diretto + fuzzy matching)
// ---------------------------------------------------------
Map<String, String>? _riconosciProdotto(String testo) {
  final t = testo.toLowerCase();

  // ---------------------------------------------------------
  // 1) MATCH DIRETTO (priorità assoluta)
  // ---------------------------------------------------------
  for (final key in _prodotti.keys) {
    if (t.contains(key)) {
      return _prodotti[key];
    }
  }

  // ---------------------------------------------------------
  // 2) MATCH FUZZY (OCR rovinato)
  // ---------------------------------------------------------
  final parole = t
      .split(RegExp(r'[^a-zA-Z]+'))
      .where((p) => p.length > 3);

  for (final p in parole) {
    final match = _fuzzyMatch(p, _prodotti.keys.toList(), soglia: 2);

    // match diverso → fuzzy match valido
    if (match != p && _prodotti.containsKey(match)) {
      return _prodotti[match];
    }
  }

  // Nessun prodotto riconosciuto
  return null;
}


// ---------------------------------------------------------
// ALGORITMO DI LEVENSHTEIN (distanza di edit)
// ---------------------------------------------------------
int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
  List<int> v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      final costo = (s[i] == t[j]) ? 0 : 1;

      v1[j + 1] = [
        v1[j] + 1,        // cancellazione
        v0[j + 1] + 1,    // inserimento
        v0[j] + costo,    // sostituzione
      ].reduce((a, b) => a < b ? a : b);
    }

    // swap vettori
    final temp = v0;
    v0 = v1;
    v1 = temp;
  }

  return v0[t.length];
}

// ---------------------------------------------------------
// DIZIONARIO PUNTI VENDITA (per fuzzy matching PdV)
// ---------------------------------------------------------
final List<String> dizionarioPuntiVendita = [
  // Catene note
  "Conad", "Coop", "Eurospin", "Lidl", "Carrefour", "MD", "Decò",
  "Mediaworld", "Unieuro", "Euronics", "Trony",
  "Eni", "Q8", "IP", "Esso", "Tamoil",
  "Zara", "OVS", "H&M", "Calzedonia",

  // Bar / Ristoranti comuni
  "Bar", "Caffetteria", "Lounge Bar", "Ristorante", "Pizzeria", "Trattoria",
  "Bistrot", "Kebab", "Sushi",

  // I tuoi PdV ricorrenti
  "Cutro Giorgio",
  "0971 Lounge Bar",
  "Milleunacialda",
  "Pretoria Caffè",
  "Da Gio",

  // Vie italiane
  "Via", "Viale", "Corso", "Piazza", "Largo", "Vico",

  // Città italiane principali
  "Potenza", "Roma", "Milano", "Napoli", "Torino", "Bari", "Firenze",
  "Bologna", "Genova", "Venezia", "Verona", "Palermo", "Catania",
];

//MOTORE CATEGORIA 4 =========================================
String _motoreCategoria4(String testo, String? puntoVendita) {
  // ---------------------------------------------------------
  // 0) NORMALIZZAZIONE INPUT
  // ---------------------------------------------------------
  final t = testo.toLowerCase();
  final pv = (puntoVendita ?? "").toLowerCase();

  // ---------------------------------------------------------
  // 1) PRIORITÀ ASSOLUTA: RICONOSCIMENTO PRODOTTI
  // ---------------------------------------------------------
  final prodotto = _riconosciProdotto(testo);
  if (prodotto != null) {
    return prodotto["categoria"]!;
  }

  // ---------------------------------------------------------
  // 2) CATEGORIA BASATA SUL PUNTO VENDITA (PdV)
  // ---------------------------------------------------------
  final mappaPdV = {
    // Ristorazione
    "pizzeria": "Ristorazione",
    "ristorante": "Ristorazione",
    "trattoria": "Ristorazione",
    "osteria": "Ristorazione",
    "da gio": "Ristorazione",
    "cutro": "Ristorazione",
    " da gio": "Ristorazione",

    // Svago
    "bar": "Svago",
    "caff": "Svago",
    "lounge": "Svago",
    "milleunacialda": "Svago",
    "pretoria": "Svago",

    // Alimentari
    "conad": "Alimentari",
    "coop": "Alimentari",
    "lidl": "Alimentari",
    "eurospin": "Alimentari",
    "carrefour": "Alimentari",
    "supermercato": "Alimentari",
    "market": "Alimentari",
    "caseificio": "Alimentari",
    "lioi": "Alimentari",

    // Salute
    "farmacia": "Salute",
    "parafarmacia": "Salute",

    // Auto
    "eni": "Auto",
    "q8": "Auto",
    "ip": "Auto",
    "esso": "Auto",
    "tamoil": "Auto",

    // Tecnologia
    "mediaworld": "Tecnologia",
    "unieuro": "Tecnologia",
    "trony": "Tecnologia",
    "euronics": "Tecnologia",

    // Abbigliamento
    "zara": "Abbigliamento",
    "ovs": "Abbigliamento",
    "h&m": "Abbigliamento",
    "calzedonia": "Abbigliamento",
  };

  for (final k in mappaPdV.keys) {
    if (pv.contains(k)) return mappaPdV[k]!;
  }

  // ---------------------------------------------------------
  // 3) CATEGORIA BASATA SUL TESTO OCR
  // ---------------------------------------------------------
  final mappaTesto = {
    // Ristorazione
    "pizza": "Ristorazione",
    "pizze": "Ristorazione",
    "panino": "Ristorazione",
    "menu": "Ristorazione",
    "hamburger": "Ristorazione",

    // Alimentari
    "caseificio": "Alimentari",
    "lioi": "Alimentari",

    // Svago
    "caff": "Svago",
    "cornetto": "Svago",
    "brioche": "Svago",

    // Salute
    "farmaci": "Salute",
    "tachipirina": "Salute",
    "paracetamolo": "Salute",

    // Auto
    "carburante": "Auto",
    "benzina": "Auto",
    "diesel": "Auto",
  };

  for (final k in mappaTesto.keys) {
    if (t.contains(k)) return mappaTesto[k]!;
  }

  // ---------------------------------------------------------
  // 4) FALLBACK FINALE
  // ---------------------------------------------------------
  return "Altro";
}



//MOTORE DESCRIZIONE 5 COMPLETA===============================
String _motoreDescrizione5(
  String testo,
  double? importo,
  DateTime? data,
  String? puntoVendita,
) {
  // ---------------------------------------------------------
  // 0) NORMALIZZAZIONE INPUT
  // ---------------------------------------------------------
  final t = testo.toLowerCase();
  final pv = (puntoVendita ?? "").toLowerCase();

  // ---------------------------------------------------------
  // 1) PRIORITÀ ASSOLUTA: RICONOSCIMENTO PRODOTTI
  // ---------------------------------------------------------
  final prodotto = _riconosciProdotto(testo);
  if (prodotto != null) {
    return prodotto["descrizione"]!;
  }

  // ---------------------------------------------------------
  // 2) DESCRIZIONE BASATA SUL PUNTO VENDITA (PdV)
  // ---------------------------------------------------------

  // 2.1) Pizzeria / Ristorante
  if (pv.contains("gio") || pv.contains("pizzeria") || pv.contains("ristorante") || pv.contains("trattoria")) {
    if (t.contains("pizza") || t.contains("pizze")) return "Pizze / Pizzeria";
    if (data != null && data.hour >= 18) return "Cena al ristorante";
    if (data != null && data.hour >= 12) return "Pranzo al ristorante";
    return "Pasto al ristorante";
  }

  // 2.2) Bar / Caffetteria
  if (pv.contains("bar") || pv.contains("caff") || pv.contains("lounge")) {
    if (t.contains("cappucc") || t.contains("caff")) return "Caffè al bar";
    if (t.contains("cornett") || t.contains("brioche")) return "Colazione al bar";
    if (data != null && data.hour >= 17 && data.hour <= 20) return "Aperitivo";
    return "Bar / Caffetteria";
  }

  // 2.3) Caseificio
  if (pv.contains("caseificio") || pv.contains("lioi")) {
    if (t.contains("mozzarella") || t.contains("fior di latte") || t.contains("scamorza")) {
      return "Prodotti freschi / Latticini";
    }
    return "Caseificio / Latticini";
  }

  // 2.4) Supermercati
  if (pv.contains("conad") || pv.contains("coop") || pv.contains("lidl") || pv.contains("eurospin") || pv.contains("carrefour")) {
    if (importo != null) {
      if (importo < 15) return "Spesa piccola";
      if (importo < 50) return "Spesa media";
      return "Spesa grande";
    }
    return "Spesa alimentare";
  }

  // 2.5) Farmacia
  if (pv.contains("farmacia") || pv.contains("parafarmacia")) {
    if (t.contains("tachipirina") || t.contains("paracetamolo")) return "Farmaci";
    return "Prodotti Farmacia";
  }

  // 2.6) Tecnologia
  if (pv.contains("mediaworld") || pv.contains("unieuro") || pv.contains("euronics") || pv.contains("trony")) {
    return "Prodotti Tecnologia";
  }

  // 2.7) Abbigliamento
  if (pv.contains("zara") || pv.contains("ovs") || pv.contains("h&m") || pv.contains("calzedonia")) {
    return "Abbigliamento";
  }

  // ---------------------------------------------------------
  // 3) RICONOSCIMENTI AVANZATI (testo + orario)
  // ---------------------------------------------------------

  // 3.1) Caffè veloce (solo se NON è un bar)
  if (!pv.contains("bar") && !pv.contains("caff") && t.contains("caff") && importo != null && importo <= 2.50) {
    return "Caffè veloce";
  }

  // 3.2) Colazione salata (solo se NON è un ristorante)
  if (!pv.contains("ristorante") &&
      !pv.contains("pizzeria") &&
      (t.contains("toast") || t.contains("panino") || t.contains("uovo")) &&
      data != null &&
      data.hour >= 7 &&
      data.hour <= 11) {
    return "Colazione salata";
  }

  // 3.3) Apericena (solo se non è ristorante)
  if (!pv.contains("ristorante") &&
      !pv.contains("pizzeria") &&
      (t.contains("spritz") || t.contains("cocktail") || t.contains("tagliere")) &&
      data != null &&
      data.hour >= 18 &&
      data.hour <= 21) {
    return "Apericena";
  }

  // 3.4) Ristorazione internazionale (solo se non è supermercato)
  if (!pv.contains("conad") &&
      !pv.contains("coop") &&
      !pv.contains("lidl") &&
      (t.contains("sushi") || t.contains("ramen") || t.contains("poke"))) {
    return "Ristorazione internazionale";
  }

  // 3.5) Pasticceria
  if (t.contains("cannolo") || t.contains("sfogliatella") || t.contains("mignon") || t.contains("torta")) {
    return "Pasticceria";
  }

  // 3.6) Prodotti premium
  if (t.contains("dop") || t.contains("igp") || t.contains("doc") || t.contains("gourmet") || t.contains("premium")) {
    return "Prodotti premium";
  }

  // ---------------------------------------------------------
  // 4) FALLBACK INTELLIGENTE DAL TESTO OCR
  // ---------------------------------------------------------
  if (t.contains("pizza")) return "Pizza";
  if (t.contains("pizze")) return "Pizze";
  if (t.contains("menu")) return "Menu";
  if (t.contains("hamburger")) return "Hamburger";
  if (t.contains("pane")) return "Panetteria / Forno";
  if (t.contains("latte") || t.contains("yogurt")) return "Prodotti da frigo";

  // ---------------------------------------------------------
  // 5) FALLBACK FINALE
  // ---------------------------------------------------------
  return "Acquisto";
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