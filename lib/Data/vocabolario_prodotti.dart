// vocabolario_prodotti.dart
// Mappa prodotti → {categoria, descrizione}
// Ordinata per categoria, parola chiave singola, senza brand.

final Map<String, Map<String, String>> productMap = {

  // ============================================================
  // 🟦 ALIMENTAZIONE
  // ============================================================
  'pane': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'pasta': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'riso': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'biscotti': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti per la colazione'},
  'cracker': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti per la colazione'},
  'fette': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti per la colazione'},
  'latte': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'yogurt': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'burro': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'uova': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'formaggio': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'mozzarella': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'ricotta': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'prosciutto': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'salame': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'mortadella': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'pollo': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'carne': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'pesce': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'tonno': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'legumi': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'fagioli': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'ceci': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'lenticchie': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'pomodoro': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'passata': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'sugo': {'categoria': 'Alimentazione', 'descrizione': 'Scatolame'},
  'olio': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'aceto': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'sale': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'zucchero': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'farina': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},
  'frutta': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'verdura': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'mele': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'banane': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'arance': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'uva': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'patate': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'cipolle': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'carote': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'insalata': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti freschi'},
  'acqua': {'categoria': 'Alimentazione', 'descrizione': 'Bevande analcoliche'},
  'bibita': {'categoria': 'Alimentazione', 'descrizione': 'Bevande analcoliche'},
  'succhi': {'categoria': 'Alimentazione', 'descrizione': 'Bevande analcoliche'},
  'birra': {'categoria': 'Alimentazione', 'descrizione': 'Bevande alcoliche'},
  'vino': {'categoria': 'Alimentazione', 'descrizione': 'Bevande alcoliche'},
  'gelato': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti surgelati'},
  'surgelati': {'categoria': 'Alimentazione', 'descrizione': 'Prodotti surgelati'},
  'semi': {'categoria': 'Alimentazione', 'descrizione': 'Spesa supermercato'},


  // ============================================================
  // 🟩 CASA
  // ============================================================
  'detersivo': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'ammorbidente': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'candeggina': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'sgrassatore': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'spugna': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'straccio': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'sacchetti': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'lampadina': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'vernice': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'martello': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'viti': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'sega a tazza': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'trapano': {'categoria': 'Casa', 'descrizione': 'Manutenzione ordinaria'},
  'tenda': {'categoria': 'Casa', 'descrizione': 'Arredamento'},
  'coperta': {'categoria': 'Casa', 'descrizione': 'Arredamento'},
  'cuscino': {'categoria': 'Casa', 'descrizione': 'Arredamento'},
  'piatti': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'bicchieri': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},
  'posate': {'categoria': 'Casa', 'descrizione': 'Prodotti per la casa'},

  // ============================================================
  // 🟧 AUTO E MOTO
  // ============================================================
  'gasolio': {'categoria': 'Auto e Moto', 'descrizione': 'Carburante'},
  'benzina': {'categoria': 'Auto e Moto', 'descrizione': 'Carburante'},
  'diesel': {'categoria': 'Auto e Moto', 'descrizione': 'Carburante'},
  'ricarica': {'categoria': 'Auto e Moto', 'descrizione': 'Ricarica auto elettrica'},
  'olio': {'categoria': 'Auto e Moto', 'descrizione': 'Manutenzione auto'},
  'filtro': {'categoria': 'Auto e Moto', 'descrizione': 'Ricambi auto'},
  'gomme': {'categoria': 'Auto e Moto', 'descrizione': 'Cambio gomme'},
  'parcheggio': {'categoria': 'Auto e Moto', 'descrizione': 'Parcheggi'},
  'pedaggio': {'categoria': 'Auto e Moto', 'descrizione': 'Pedaggi autostradali'},
  'assicurazione': {'categoria': 'Auto e Moto', 'descrizione': 'Assicurazione auto'},
  'bollo': {'categoria': 'Auto e Moto', 'descrizione': 'Bollo auto'},
  'tagliando': {'categoria': 'Auto e Moto', 'descrizione': 'Tagliando auto'},
  'lavaggio': {'categoria': 'Auto e Moto', 'descrizione': 'Lavaggio auto'},

  // ============================================================
  // 🟪 SALUTE E BENESSERE
  // ============================================================
  'farmaco': {'categoria': 'Salute e Benessere', 'descrizione': 'Farmacia'},
  'cerotto': {'categoria': 'Salute e Benessere', 'descrizione': 'Farmacia'},
  'integratore': {'categoria': 'Salute e Benessere', 'descrizione': 'Integratori'},
  'vitamine': {'categoria': 'Salute e Benessere', 'descrizione': 'Integratori'},
  'shampoo': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'bagnoschiuma': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'dentifricio': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'spazzolino': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'collutorio': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'crema': {'categoria': 'Salute e Benessere', 'descrizione': 'Prodotti per la cura personale'},
  'ceretta': {'categoria': 'Salute e Benessere', 'descrizione': 'Estetista'},

  // ============================================================
  // 🟫 ANIMALI DOMESTICI
  // ============================================================
  'crocchette': {'categoria': 'Animali domestici', 'descrizione': 'Cibo per animali'},
  'lettiera': {'categoria': 'Animali domestici', 'descrizione': 'Pulizia e igiene'},
  'antiparassitario': {'categoria': 'Animali domestici', 'descrizione': 'Antiparassitari'},
  'guinzaglio': {'categoria': 'Animali domestici', 'descrizione': 'Accessori'},
  'ciotola': {'categoria': 'Animali domestici', 'descrizione': 'Accessori'},
  'gioco': {'categoria': 'Animali domestici', 'descrizione': 'Giochi'},

  // ============================================================
  // 🟨 CASA / UTENZE
  // ============================================================
  'energia': {'categoria': 'Utenze', 'descrizione': 'Energia elettrica'},
  'gas': {'categoria': 'Utenze', 'descrizione': 'Gas naturale'},
  'internet': {'categoria': 'Utenze', 'descrizione': 'Internet fibra'},
  'telefono': {'categoria': 'Utenze', 'descrizione': 'Telefonia mobile'},
  'acqua': {'categoria': 'Utenze', 'descrizione': 'Acqua'},

// ============================================================
  // 🟨 RISTORAZIONE / BAR /PIZZERIE
  // ============================================================
  'ginseng': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'caffè': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'Cappuccino': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'Primo': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Ristorante'},
  'Secondo': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Ristorante'},
  'Contorno': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Ristorante'},
  'Cornetto': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'Spremuta': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'Aperitivo': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Consumazione al bar'},
  'Ristorante': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Ristorante'},
  'Pizza': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Pizzeria'},
  'Pizze': {'categoria': 'Ristorazione-Bar', 'descrizione': 'Pizzeria'},
};