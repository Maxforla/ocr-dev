import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/movimento.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();
Future<void> deleteAllMovimenti() async {
  final db = await database;
  await db.delete('movimenti');
  print("DEBUG DB: tutti i movimenti cancellati");
}
Future<void> pulisciDuplicati({
  required String tabella,
  required String campo,
}) async {
  final db = await database;

  final rows = await db.query(tabella);

  final Map<String, int> canonical = {};

  for (final row in rows) {
    final id = row['id'] as int;
    final valore = row[campo] as String;

    final norm = normalizeSmart(valore);

    if (!canonical.containsKey(norm)) {
      canonical[norm] = id; // tieni la prima voce
    } else {
      await db.delete(
        tabella,
        where: 'id = ?',
        whereArgs: [id],
      );
      print("DEBUG CLEAN: eliminato duplicato in $tabella → $valore");
    }
  }
}

  // -------------------------------------------------------------
  // INIZIO PATCH — FUNZIONI DI NORMALIZZAZIONE E FORMATTAZIONE
  // -------------------------------------------------------------

  /// Normalizzazione intelligente dei testi.
  /// - Rimuove spazi doppi
  /// - Converte in minuscolo e poi capitalizza correttamente
  /// - Gestisce sigle, punti vendita, metodi di pagamento
  String normalizeSmart(String input) {
    if (input.trim().isEmpty) return "";

    String cleaned = input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    // Capitalizzazione intelligente
    cleaned = cleaned.split(" ").map((word) {
      if (word.length <= 2) return word.toUpperCase(); // sigle tipo "IP", "ENI"
      return word[0].toUpperCase() + word.substring(1);
    }).join(" ");

    return cleaned;
  }
String normalizeSearch(String input) {
  if (input.trim().isEmpty) return "";

  String cleaned = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')   // rimuove punteggiatura
      .replaceAll(RegExp(r'\s+'), ' ')      // spazi multipli → singolo
      .trim();

  return cleaned;
}

  /// Converte un double in formato euro "1.234,56"
  

String formatEuro(double value) {
  final formatter = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '',
    decimalDigits: 2,
  );
  return formatter.format(value).trim();
}

  /// Parsing robusto:
  /// accetta "12,50", "12.50", "1.234,56", "1234.56"
  double parseEuroToDouble(String input) {
    if (input.trim().isEmpty) return 0.0;

    String cleaned = input.trim();

    // Rimuove separatori migliaia
    cleaned = cleaned.replaceAll('.', '');

    // Converte virgola in punto
    cleaned = cleaned.replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  // -------------------------------------------------------------
  // FINE PATCH — FUNZIONI DI NORMALIZZAZIONE E FORMATTAZIONE
  // -------------------------------------------------------------


  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'spese.db');

  final db = await openDatabase(
    path,
    version: 12,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  print(await db.rawQuery('SELECT * FROM macroaree'));

  return db;
}

  /* ============================
     ON CREATE
     ============================ */
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE movimenti (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  data TEXT NOT NULL,
  tipo TEXT NOT NULL,
  categoria TEXT NOT NULL,
  descrizione TEXT NOT NULL,
  importo REAL NOT NULL,
  puntoVendita TEXT,
  metodoPagamento TEXT,
  nota TEXT,
  origine TEXT,
  searchCategoria TEXT,
  searchDescrizione TEXT,
  searchPuntoVendita TEXT,
  searchMetodoPagamento TEXT,
  dataCreazione TEXT,
  idMacroarea INTEGER,
  FOREIGN KEY(idMacroarea) REFERENCES macroaree(id)
);
  ''');

await db.execute('''
  CREATE TABLE macroaree (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL UNIQUE,
    percentuale INTEGER NOT NULL
  );
''');

    await db.execute('''
  CREATE TABLE categorie (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    tipo TEXT NOT NULL,
    idMacroarea INTEGER NOT NULL,
    FOREIGN KEY(idMacroarea) REFERENCES macroaree(id),
    UNIQUE(nome, tipo)
  );
''');

    await db.execute('''
      CREATE TABLE descrizioni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT,
        categoria TEXT,
        descrizione TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE metodi_pagamento (
        nome TEXT PRIMARY KEY
      );
    ''');

    await db.execute('''
      CREATE TABLE punti_vendita (
        nome TEXT PRIMARY KEY
      );
    ''');

    await seedDatabase(db);
  }

  /* ============================
     ON UPGRADE
     ============================ */
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE movimenti ADD COLUMN nota TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('CREATE TABLE metodi_pagamento (nome TEXT PRIMARY KEY)');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE descrizioni ADD COLUMN tipo TEXT');
    }

    if (oldVersion < 6) {
      await db.execute("ALTER TABLE movimenti ADD COLUMN searchCategoria TEXT;");
      await db.execute("ALTER TABLE movimenti ADD COLUMN searchDescrizione TEXT;");
      await db.execute("ALTER TABLE movimenti ADD COLUMN searchPuntoVendita TEXT;");
    }

    if (oldVersion < 7) {
      await db.execute("ALTER TABLE movimenti ADD COLUMN dataCreazione INTEGER");
    }
    if (oldVersion < 9) {
  // 1. Aggiunta nuova colonna searchMetodoPagamento
  await db.execute("ALTER TABLE movimenti ADD COLUMN searchMetodoPagamento TEXT;");

  // 2. Popolamento di tutti i campi search
  await db.execute("""
    UPDATE movimenti SET
      searchCategoria = LOWER(categoria),
      searchDescrizione = LOWER(descrizione),
      searchPuntoVendita = LOWER(puntoVendita),
      searchMetodoPagamento = LOWER(metodoPagamento)
  """);
    }
   // ⭐ NUOVA MIGRAZIONE: conversione timestamp → ISO
  if (oldVersion < 11) {
    await db.rawQuery('''
      UPDATE movimenti
      SET data = datetime(data / 1000, 'unixepoch')
      WHERE typeof(data) = 'integer';
    ''');
  }
}


  /* ============================
     SEED
     ============================ */
  Future<void> seedDatabase(Database db) async {
   // SEED MACROAREE 50-30-20
final countMacro = Sqflite.firstIntValue(
  await db.rawQuery('SELECT COUNT(*) FROM macroaree'),
);

if (countMacro == 0) {
  await db.insert('macroaree', {
    'nome': 'Necessità',
    'percentuale': 50,
  });

  await db.insert('macroaree', {
    'nome': 'Desideri',
    'percentuale': 30,
  });

  await db.insert('macroaree', {
    'nome': 'Risparmio',
    'percentuale': 20,
  });
}

// SEED CATEGORIE COLLEGATE ALLE MACROAREE
final countCat = Sqflite.firstIntValue(
  await db.rawQuery('SELECT COUNT(*) FROM categorie'),
);

if (countCat == 0) {
  // Helper per ottenere idMacroarea
  Future<int> getIdMacroarea(String nome) async {
    final res = await db.query(
      'macroaree',
      where: 'nome = ?',
      whereArgs: [nome],
      limit: 1,
    );
    return res.first['id'] as int;
  }

  final idNecessita = await getIdMacroarea('Necessità');
  final idDesideri = await getIdMacroarea('Desideri');
  final idRisparmio = await getIdMacroarea('Risparmio');

  final categorie = [
    // NECESSITÀ (50%)
    {'nome': 'Affitto',        'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Mutuo',          'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Utenze',         'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Alimentari',     'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Trasporti',      'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Assicurazioni',  'tipo': 'uscita', 'idMacroarea': idNecessita},
    {'nome': 'Altro',          'tipo': 'uscita', 'idMacroarea': idNecessita},

    // DESIDERI (30%)
    {'nome': 'Ristoranti',     'tipo': 'uscita', 'idMacroarea': idDesideri},
    {'nome': 'Shopping',       'tipo': 'uscita', 'idMacroarea': idDesideri},
    {'nome': 'Viaggi',         'tipo': 'uscita', 'idMacroarea': idDesideri},
    {'nome': 'Intrattenimento','tipo': 'uscita', 'idMacroarea': idDesideri},
    {'nome': 'Hobby',          'tipo': 'uscita', 'idMacroarea': idDesideri},

    // RISPARMIO (20%)
    {'nome': 'Risparmio',      'tipo': 'uscita', 'idMacroarea': idRisparmio},
    {'nome': 'Investimenti',   'tipo': 'uscita', 'idMacroarea': idRisparmio},
    {'nome': 'Fondo emergenza','tipo': 'uscita', 'idMacroarea': idRisparmio},
    {'nome': 'Prestiti',       'tipo': 'uscita', 'idMacroarea': idRisparmio},

    // ENTRATE
    {'nome': 'Stipendio',      'tipo': 'entrata', 'idMacroarea': idNecessita},
    {'nome': 'Entrate extra',  'tipo': 'entrata', 'idMacroarea': idDesideri},
  ];

  for (final c in categorie) {
    await db.insert('categorie', c, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}


    final countDesc = Sqflite.firstIntValue(
  await db.rawQuery('SELECT COUNT(*) FROM descrizioni'),
);

if (countDesc == 0) {
  final descrizioni = [
    // AFFITTO
    {'tipo': 'uscita', 'categoria': 'Affitto', 'descrizione': 'Canone mensile'},
    {'tipo': 'uscita', 'categoria': 'Affitto', 'descrizione': 'Condominio'},

    // MUTUO
    {'tipo': 'uscita', 'categoria': 'Mutuo', 'descrizione': 'Rata mensile'},
    {'tipo': 'uscita', 'categoria': 'Mutuo', 'descrizione': 'Interessi'},

    // UTENZE
    {'tipo': 'uscita', 'categoria': 'Utenze', 'descrizione': 'Luce'},
    {'tipo': 'uscita', 'categoria': 'Utenze', 'descrizione': 'Gas'},
    {'tipo': 'uscita', 'categoria': 'Utenze', 'descrizione': 'Acqua'},
    {'tipo': 'uscita', 'categoria': 'Utenze', 'descrizione': 'Internet'},

    // ALIMENTARI
    {'tipo': 'uscita', 'categoria': 'Alimentari', 'descrizione': 'Spesa settimanale'},
    {'tipo': 'uscita', 'categoria': 'Alimentari', 'descrizione': 'Supermercato'},
    {'tipo': 'uscita', 'categoria': 'Alimentari', 'descrizione': 'Prodotti freschi'},

    // TRASPORTI
    {'tipo': 'uscita', 'categoria': 'Trasporti', 'descrizione': 'Carburante'},
    {'tipo': 'uscita', 'categoria': 'Trasporti', 'descrizione': 'Manutenzione auto'},
    {'tipo': 'uscita', 'categoria': 'Trasporti', 'descrizione': 'Assicurazione auto'},
    {'tipo': 'uscita', 'categoria': 'Trasporti', 'descrizione': 'Mezzi pubblici'},

    // ASSICURAZIONI
    {'tipo': 'uscita', 'categoria': 'Assicurazioni', 'descrizione': 'Polizza casa'},
    {'tipo': 'uscita', 'categoria': 'Assicurazioni', 'descrizione': 'Polizza vita'},
    {'tipo': 'uscita', 'categoria': 'Assicurazioni', 'descrizione': 'Polizza sanitaria'},

    // RISTORANTI
    {'tipo': 'uscita', 'categoria': 'Ristoranti', 'descrizione': 'Cena fuori'},
    {'tipo': 'uscita', 'categoria': 'Ristoranti', 'descrizione': 'Pranzo veloce'},
    {'tipo': 'uscita', 'categoria': 'Ristoranti', 'descrizione': 'Aperitivo'},

    // SHOPPING
    {'tipo': 'uscita', 'categoria': 'Shopping', 'descrizione': 'Abbigliamento'},
    {'tipo': 'uscita', 'categoria': 'Shopping', 'descrizione': 'Scarpe'},
    {'tipo': 'uscita', 'categoria': 'Shopping', 'descrizione': 'Accessori'},

    // VIAGGI
    {'tipo': 'uscita', 'categoria': 'Viaggi', 'descrizione': 'Hotel'},
    {'tipo': 'uscita', 'categoria': 'Viaggi', 'descrizione': 'Volo'},
    {'tipo': 'uscita', 'categoria': 'Viaggi', 'descrizione': 'Noleggio auto'},

    // INTRATTENIMENTO
    {'tipo': 'uscita', 'categoria': 'Intrattenimento', 'descrizione': 'Cinema'},
    {'tipo': 'uscita', 'categoria': 'Intrattenimento', 'descrizione': 'Concerti'},
    {'tipo': 'uscita', 'categoria': 'Intrattenimento', 'descrizione': 'Eventi'},

    // HOBBY
    {'tipo': 'uscita', 'categoria': 'Hobby', 'descrizione': 'Sport'},
    {'tipo': 'uscita', 'categoria': 'Hobby', 'descrizione': 'Strumenti musicali'},
    {'tipo': 'uscita', 'categoria': 'Hobby', 'descrizione': 'Materiale creativo'},

    // RISPARMIO
    {'tipo': 'uscita', 'categoria': 'Risparmio', 'descrizione': 'Accantonamento mensile'},
    {'tipo': 'uscita', 'categoria': 'Risparmio', 'descrizione': 'Obiettivo annuale'},

    // INVESTIMENTI
    {'tipo': 'uscita', 'categoria': 'Investimenti', 'descrizione': 'ETF'},
    {'tipo': 'uscita', 'categoria': 'Investimenti', 'descrizione': 'Azioni'},
    {'tipo': 'uscita', 'categoria': 'Investimenti', 'descrizione': 'PAC'},

    // FONDO EMERGENZA
    {'tipo': 'uscita', 'categoria': 'Fondo emergenza', 'descrizione': 'Accantonamento'},

    // PRESTITI
    {'tipo': 'uscita', 'categoria': 'Prestiti', 'descrizione': 'Rimborso mensile'},

    // ENTRATE
    {'tipo': 'entrata', 'categoria': 'Stipendio', 'descrizione': 'Mensile'},
    {'tipo': 'entrata', 'categoria': 'Stipendio', 'descrizione': 'Bonus'},
    {'tipo': 'entrata', 'categoria': 'Entrate extra', 'descrizione': 'Vendite'},
    {'tipo': 'entrata', 'categoria': 'Entrate extra', 'descrizione': 'Lavoretti'},
  ];

  for (final d in descrizioni) {
    await db.insert('descrizioni', d, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}


    final countMetodi = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM metodi_pagamento'),
    );

    if (countMetodi == 0) {
      final metodi = [
        {'nome': 'Contanti'},
        {'nome': 'Bancomat'},
        {'nome': 'Carta di credito'},
      ];

      for (final m in metodi) {
        await db.insert('metodi_pagamento', m);
      }
    }

    final countPV = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM punti_vendita'),
    );

    if (countPV == 0) {
      final pv = [
        {'nome': 'Conad'},
        {'nome': 'Coop'},
        {'nome': 'Amazon'},
      ];

      for (final p in pv) {
        await db.insert('punti_vendita', p);
      }
    }
  }

  /* ============================
     CATEGORIE
     ============================ */

Future<void> insertCategoria({
  required MovimentoTipo tipo,
  required String nome,
  required int idMacroarea,
}) async {
  final db = await database;

  final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

  await db.insert(
    'categorie',
    {
      'nome': normalizeSmart(nome),
      'tipo': tipoString,
      'idMacroarea': idMacroarea,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}




  Future<List<String>> getCategorie({
    required MovimentoTipo tipo,
  }) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    final res = await db.query(
      'categorie',
      where: 'tipo = ?',
      whereArgs: [tipoString],
      orderBy: 'LOWER(nome) ASC',
    );

    return res
        .map((r) => r['nome'])
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();
  }




  Future<void> updateCategoria({
    required MovimentoTipo tipo,
    required String oldNome,
    required String newNome,
  }) async {
    final db = await database;


    await db.update(
      'categorie',
      {'nome': normalizeSmart(newNome)},
      where: 'tipo = ? AND nome = ?',
      whereArgs: [tipo.name, oldNome],
    );
  }

  Future<int> deleteCategoria(String nome, String tipo) async {
    final db = await database;
    return await db.delete(
      'categorie',
      where: 'nome = ? AND tipo = ?',
      whereArgs: [nome, tipo],
    );
  }

  /* ============================
     DESCRIZIONI
     ============================ */

  Future<List<String>> getDescrizioni({
    required MovimentoTipo tipo,
    required String categoria,
  }) async {
    final db = await database;

    final res = await db.query(
      'descrizioni',
      where: 'tipo = ? AND categoria = ?',
      whereArgs: [tipo.name, categoria],
      orderBy: 'descrizione ASC',
    );

    return res.map((e) => e['descrizione'] as String).toList();
  }

  Future<int> insertDescrizione({
    required MovimentoTipo tipo,
    required String categoria,
    required String descrizione,
  }) async {
    final db = await database;

    return await db.insert(
      'descrizioni',
      {
        'tipo': tipo.name,
        'categoria': normalizeSmart(categoria),
        'descrizione': normalizeSmart(descrizione),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> updateDescrizione({
    required MovimentoTipo tipo,
    required String categoria,
    required String oldDescrizione,
    required String newDescrizione,
  }) async {
    final db = await database;

    return await db.update(
      'descrizioni',
      {'descrizione': normalizeSmart(newDescrizione)},
      where: 'tipo = ? AND categoria = ? AND descrizione = ?',
      whereArgs: [tipo.name, categoria, oldDescrizione],
    );
  }

  Future<int> deleteDescrizione({
    required MovimentoTipo tipo,
    required String categoria,
    required String descrizione,
  }) async {
    final db = await database;

    return await db.delete(
      'descrizioni',
      where: 'tipo = ? AND categoria = ? AND descrizione = ?',
      whereArgs: [tipo.name, categoria, descrizione],
    );
  }

  /* ============================
     METODI PAGAMENTO
     ============================ */

  Future<List<String>> getMetodiPagamento() async {
    final db = await database;
    final res = await db.query(
      'metodi_pagamento',
      orderBy: 'LOWER(nome) ASC',
    );
    return res.map((e) => e['nome'] as String).toList();
  }

  Future<int> insertMetodoPagamento(String nome) async {
    final db = await database;
    return await db.insert(
      'metodi_pagamento',
     {'nome': normalizeSmart(nome)},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> updateMetodoPagamento({
    required String oldNome,
    required String newNome,
  }) async {
    final db = await database;
    return await db.update(
      'metodi_pagamento',
      {'nome': normalizeSmart(newNome)},
      where: 'nome = ?',
      whereArgs: [oldNome],
    );
  }


  Future<int> deleteMetodoPagamento(String nome) async {
    final db = await database;
    return await db.delete(
      'metodi_pagamento',
      where: 'nome = ?',
      whereArgs: [nome],
    );
  }

  /* ============================
     PUNTI VENDITA
     ============================ */

  Future<List<String>> getPuntiVenditaListaCompleta() async {
    final db = await database;
    final res = await db.query(
      'punti_vendita',
      orderBy: 'LOWER(nome) ASC',
    );
    return res.map((e) => e['nome'] as String).toList();
  }
  Future<void> aggiungiDescrizione({
    required MovimentoTipo tipo,
    required String categoria,
    required String descrizione,
  }) async {
    final db = await database;
    await db.insert(
      'descrizioni',
      {
        'tipo': tipo.name,        // 🔥 aggiunto
        'categoria': categoria,
        'descrizione': descrizione,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  Future<void> aggiungiCategoria({
    required MovimentoTipo tipo,
    required String categoria,
  }) async {
    final db = await database;
    await db.insert(
      'categorie',
      {
        'tipo': tipo == MovimentoTipo.entrata ? 'entrata' : 'uscita',
        'categoria': categoria,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  Future<void> aggiungiMetodoPagamento(String metodo) async {
    final db = await database;
    await db.insert(
      'metodi_pagamento',
      {
        'nome': normalizeSmart(metodo),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> insertPuntoVendita(String nome) async {
    final db = await database;
    return await db.insert(
      'punti_vendita',
      {'nome': normalizeSmart(nome)},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> updatePuntoVendita({
    required String oldNome,
    required String newNome,
  }) async {
    final db = await database;
    return await db.update(
      'punti_vendita',
      {'nome': normalizeSmart(newNome)},
      where: 'nome = ?',
      whereArgs: [oldNome],
    );
  }

  Future<int> deletePuntoVendita(String nome) async {
    final db = await database;
    return await db.delete(
      'punti_vendita',
      where: 'nome = ?',
      whereArgs: [nome],
    );
  }

  /* ============================
     MOVIMENTI
     ============================ */

  Future<List<Movimento>> getMovimenti() async {
    final db = await database;
    final res = await db.query(
      'movimenti',
      orderBy: 'data DESC',
    );
    return res.map((e) => Movimento.fromMap(e)).toList();
  }

  Future<int> insertMovimento(Movimento m) async {
  print('DEBUG DB: entro in insertMovimento con: ${m.toMap()}');
  final db = await database;

  final map = m.toMap();

  // Salvo la categoria originale PRIMA della normalizzazione
  final categoriaOriginale = map['categoria'];

  // Normalizzazioni
  map['categoria'] = map['categoria'];
// ❌ NON normalizzare la descrizione qui
// map['descrizione'] = normalizeSmart(map['descrizione'] ?? "");
map['puntoVendita'] = normalizeSmart(map['puntoVendita'] ?? "");
map['metodoPagamento'] = normalizeSmart(map['metodoPagamento'] ?? "");
map['nota'] = normalizeSmart(map['nota'] ?? "");

  map['origine'] = m.origine.name;

  map['importo'] = m.importo;

  // Assegno la macroarea SOLO alle uscite.
  // Le entrate NON devono finire in nessuna macroarea.
  if (m.tipo == MovimentoTipo.uscita) {
    final res = await db.query(
      'categorie',
      where: 'nome = ?',
      whereArgs: [categoriaOriginale],
      limit: 1,
    );

    if (res.isEmpty) {
      print("ERRORE: categoria non trovata: $categoriaOriginale");
      throw Exception('Categoria non trovata: $categoriaOriginale');
    }

    final idMacroarea = res.first['idMacroarea'];
    map['idMacroarea'] = idMacroarea;
  } else {
    // ENTRATA → nessuna macroarea
    map['idMacroarea'] = null;
  }


  // Campi ricerca smart
  map['searchCategoria'] = normalizeSearch(map['categoria']);
  map['searchDescrizione'] = normalizeSearch(map['descrizione']);
  map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita']);
  map['searchMetodoPagamento'] = normalizeSearch(map['metodoPagamento']);

  print("MOVIMENTO SALVATO: $map");
print('DEBUG DB: sto per fare db.insert movimenti con map: $map');
  return await db.insert(
    'movimenti',
    map,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

  Future<int> updateMovimento(Movimento m) async {
    final db = await database;

    final map = m.toMap();

    final categoriaOriginale = map['categoria'];  // salva la versione originale
    map['categoria'] = map['categoria'];
    map['descrizione'] = normalizeSmart(map['descrizione'] ?? "");
    map['puntoVendita'] = normalizeSmart(map['puntoVendita'] ?? "");
    map['metodoPagamento'] = normalizeSmart(map['metodoPagamento'] ?? "");
    map['nota'] = normalizeSmart(map['nota'] ?? "");
    map['origine'] = normalizeSmart(map['origine'] ?? "");

    map['importo'] = m.importo;

    map['searchCategoria'] = normalizeSearch(map['categoria']);
    map['searchDescrizione'] = normalizeSearch(map['descrizione']);
    map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita']);
    map['searchMetodoPagamento'] = normalizeSearch(map['metodoPagamento']); 
    return await db.update(
      'movimenti',
      map,
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> deleteMovimento(int id) async {
    final db = await database;
    return await db.delete(
      'movimenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<List<Movimento>> searchMovimentiGoogle(String query) async {
  final db = await database;

  // 1. Normalizza la query
  final cleaned = normalizeSearch(query);

  if (cleaned.isEmpty) {
    return getMovimenti(); // se vuoto → ritorna tutto
  }

  // 2. Tokenizza (es: "conad bancomat" → ["conad", "bancomat"])
  final tokens = cleaned.split(" ");

  // 3. Costruzione dinamica della WHERE
  final whereClauses = <String>[];
  final whereArgs = <String>[];

  for (final token in tokens) {
    whereClauses.add("""
      (
        searchCategoria LIKE ? OR
        searchDescrizione LIKE ? OR
        searchPuntoVendita LIKE ? OR
        searchMetodoPagamento LIKE ?
      )
    """);

    whereArgs.addAll([
      "%$token%",
      "%$token%",
      "%$token%",
      "%$token%",
    ]);
  }

  final whereString = whereClauses.join(" AND ");

  // 4. Esecuzione query
  final res = await db.query(
    'movimenti',
    where: whereString,
    whereArgs: whereArgs,
    orderBy: 'data DESC',
  );

  return res.map((e) => Movimento.fromMap(e)).toList();
}

/*==============================
FUNZIONI DASHBOARD 50-30-20
================================*/

Future<double> getTotaleEntrateMese(int year, int month) async {
  final db = await database;

  final res = await db.rawQuery('''
    SELECT SUM(importo) AS totale
    FROM movimenti
    WHERE tipo = 'entrata'
      AND strftime('%Y', data) = ?
      AND strftime('%m', data) = ?
  ''', [
    year.toString(),
    month.toString().padLeft(2, '0'),
  ]);

  final value = res.first['totale'];
  return value == null ? 0.0 : (value as num).toDouble();
}


Future<Map<String, double>> getUscitePerMacroarea(int year, int month) async {
  final db = await database;

  final res = await db.rawQuery('''
    SELECT m.idMacroarea, SUM(m.importo) AS totale
    FROM movimenti m
    WHERE m.tipo = 'uscita'
      AND strftime('%Y', m.data) = ?
      AND strftime('%m', m.data) = ?
    GROUP BY m.idMacroarea
  ''', [
    year.toString(),
    month.toString().padLeft(2, '0'),
  ]);

  final macro = await db.query('macroaree');

  final result = <String, double>{};

  for (final row in res) {
    final id = row['idMacroarea'] as int;
    final totale = row['totale'] == null ? 0.0 : (row['totale'] as num).toDouble();

    final nome = macro.firstWhere((m) => m['id'] == id)['nome'] as String;

    result[nome] = totale;
  }

  return result;
}

Future<double> getTotaleUsciteMese(int year, int month) async {
  final db = await database;

  final res = await db.rawQuery('''
    SELECT SUM(importo) AS totale
    FROM movimenti
    WHERE tipo = 'uscita'
      AND strftime('%Y', data) = ?
      AND strftime('%m', data) = ?
  ''', [
    year.toString(),
    month.toString().padLeft(2, '0'),
  ]);

  final value = res.first['totale'];
  return value == null ? 0.0 : (value as num).toDouble();
}


  /* ============================
     PREDITTIVI
     ============================ */

  Future<List<String>> getCategoriePredittive({required MovimentoTipo tipo}) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    // 1. Categorie usate nei movimenti
    final usate = await db.rawQuery('''
    SELECT categoria, COUNT(*) AS freq
    FROM movimenti
    WHERE tipo = ?
    GROUP BY categoria
    ORDER BY freq DESC
  ''', [tipoString]);

    final usateList = usate
        .map((e) => e['categoria'])
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();

    // 2. Tutte le categorie disponibili
    final tutte = await db.rawQuery('''
    SELECT nome
    FROM categorie
    WHERE tipo = ?
    ORDER BY nome ASC
  ''', [tipoString]);

    final tutteList = tutte
        .map((e) => e['nome'])
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();

    // 3. Risultato
    final result = [
      ...usateList,
      ...tutteList.where((c) => !usateList.contains(c)),
    ];

    return result;
  }

Future<List<String>> getCategorieByTipo(MovimentoTipo tipo) async {
  final db = await database;

  final res = await db.query(
    'categorie',
    columns: ['nome'],
    where: 'tipo = ?',
    whereArgs: [tipo == MovimentoTipo.uscita ? 'uscita' : 'entrata'],
    orderBy: 'nome COLLATE NOCASE ASC',
  );

  return res.map((e) => e['nome'] as String).toList();
}


  Future<List<String>> getDescrizioniPredittive({
    required MovimentoTipo tipo,
    required String categoria,
  }) async {
    final db = await database;

    // Descrizioni usate nei movimenti, ordinate per frequenza
    final usate = await db.rawQuery('''
    SELECT descrizione, COUNT(*) AS freq
    FROM movimenti
    WHERE tipo = ? AND categoria = ?
    GROUP BY descrizione
    ORDER BY freq DESC
  ''', [tipo.name, categoria]);

    final usateList = usate.map((e) => e['descrizione'] as String).toList();

    // Tutte le descrizioni disponibili per quella categoria
    final tutte = await getDescrizioni(tipo: tipo, categoria: categoria);

    // Risultato: prima le usate, poi le altre
    final result = [
      ...usateList,
      ...tutte.where((d) => !usateList.contains(d)),
    ];

    return result;
  }

Future<String?> getMetodoPagamentoByPuntoVendita(String puntoVendita) async {
  final db = await database;

  final res = await db.query(
    'movimenti',
    columns: ['metodoPagamento'],
    where: 'puntoVendita = ?',
    whereArgs: [puntoVendita],
    orderBy: 'id DESC',
    limit: 1,
  );

  if (res.isNotEmpty) {
    return res.first['metodoPagamento'] as String?;
  }

  return null;
}


  Future<List<String>> getMetodiPagamentoListaCompleta() async {
    return getMetodiPagamento();
  }

  Future<List<String>> getMetodiPagamentoFiltrati(String filtro) async {
    final db = await database;

    final res = await db.query(
      'metodi_pagamento',
      where: 'LOWER(nome) LIKE ?',
      whereArgs: ['%${filtro.toLowerCase()}%'],
      orderBy: 'LOWER(nome) ASC',
    );

    return res.map((e) => e['nome'] as String).toList();
  }
  Future<Map<String, String>?> getCategoriaDescrizioneByPuntoVendita(String puntoVendita) async {
    final db = await database;

    final result = await db.query(
      'movimenti',
      where: 'puntoVendita = ?',
      whereArgs: [puntoVendita],
    );

    if (result.isEmpty) return null;

    // Prendi il movimento più recente
    final row = result.last;

    return {
      "categoria": row["categoria"] as String,
      "descrizione": row["descrizione"] as String,
    };
  }

  Future<List<String>> getNoteUsate() async {
    final db = await database;

    final res = await db.rawQuery('''
      SELECT DISTINCT nota
      FROM movimenti
      WHERE nota IS NOT NULL AND nota <> ''
      ORDER BY nota ASC
    ''');

    return res.map((e) => e['nota'] as String).toList();
  }
}