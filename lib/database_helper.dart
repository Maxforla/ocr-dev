import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'models/movimento.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

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

    return openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  /* ============================
     ON CREATE
     ============================ */
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movimenti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT,
        data INTEGER,
        categoria TEXT,
        descrizione TEXT,
        importo REAL,
        puntoVendita TEXT,
        metodoPagamento TEXT,
        nota TEXT,
        origine TEXT,
        searchCategoria TEXT,
        searchDescrizione TEXT,
        searchPuntoVendita TEXT,
        dataCreazione INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE categorie (
        nome TEXT,
        tipo TEXT,
        PRIMARY KEY (nome, tipo)
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
  }


  /* ============================
     SEED
     ============================ */
  Future<void> seedDatabase(Database db) async {
    final countCat = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categorie'),
    );

    if (countCat == 0) {
      final categorie = [
        {'nome': 'Casa', 'tipo': 'uscita'},
        {'nome': 'Alimentazione', 'tipo': 'uscita'},
        {'nome': 'Trasporti', 'tipo': 'uscita'},
        {'nome': 'Stipendio', 'tipo': 'entrata'},
        {'nome': 'Vendite', 'tipo': 'entrata'},
      ];

      for (final c in categorie) {
        await db.insert('categorie', c);
      }
    }

    final countDesc = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM descrizioni'),
    );

    if (countDesc == 0) {
      final descrizioni = [
        {'tipo': 'uscita', 'categoria': 'Casa', 'descrizione': 'Affitto'},
        {'tipo': 'uscita', 'categoria': 'Casa', 'descrizione': 'Luce'},
        {'tipo': 'uscita', 'categoria': 'Alimentazione', 'descrizione': 'Spesa'},
        {'tipo': 'entrata', 'categoria': 'Stipendio', 'descrizione': 'Mensile'},
      ];

      for (final d in descrizioni) {
        await db.insert('descrizioni', d);
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
  }) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    await db.insert(
      'categorie',
      {
        'nome': normalizeSmart(nome),
        'tipo': tipoString,
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
    final db = await database;

    final map = m.toMap();

    map['categoria'] = normalizeSmart(map['categoria'] ?? "");
    map['descrizione'] = normalizeSmart(map['descrizione'] ?? "");
    map['puntoVendita'] = normalizeSmart(map['puntoVendita'] ?? "");
    map['metodoPagamento'] = normalizeSmart(map['metodoPagamento'] ?? "");
    map['nota'] = normalizeSmart(map['nota'] ?? "");
    map['origine'] = m.origine.name;


      map['importo'] = m.importo;

    //Campi Ricerca Smart
    map['searchCategoria'] = normalizeSearch(map['categoria']);
    map['searchDescrizione'] = normalizeSearch(map['descrizione']);
    map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita']);

    return await db.insert(
      'movimenti',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMovimento(Movimento m) async {
    final db = await database;

    final map = m.toMap();

    map['categoria'] = normalizeSmart(map['categoria'] ?? "");
    map['descrizione'] = normalizeSmart(map['descrizione'] ?? "");
    map['puntoVendita'] = normalizeSmart(map['puntoVendita'] ?? "");
    map['metodoPagamento'] = normalizeSmart(map['metodoPagamento'] ?? "");
    map['nota'] = normalizeSmart(map['nota'] ?? "");
    map['origine'] = normalizeSmart(map['origine'] ?? "");

    map['importo'] = m.importo;

    map['searchCategoria'] = normalizeSearch(map['categoria']);
    map['searchDescrizione'] = normalizeSearch(map['descrizione']);
    map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita']);

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