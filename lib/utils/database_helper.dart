// ===============================================================
// DATABASE HELPER — VERSIONE RISCRITTA E MODULARE
// Compatibile con OCR avanzato, vocabolari, dashboard 50-30-20
// ===============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/movimento.dart';

// ===============================================================
// RISULTATO INSERIMENTO MOVIMENTO (SAFE)
// ===============================================================

class InsertResult {
  final bool success;
  final String? errorCode;    // es: "categoria_non_esistente"
  final String? errorMessage; // messaggio umano
  final Movimento? movimento; // opzionale: movimento coinvolto

  const InsertResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.movimento,
  });
}

// ===============================================================
// SINGLETON
// ===============================================================

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ===============================================================
  // INIT DATABASE
  // ===============================================================

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'spese.db');

    final db = await openDatabase(
      path,
      version: 13,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return db;
  }

  // ===============================================================
  // ON CREATE — TABELLE ORIGINALI
  // ===============================================================

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
        articoli TEXT,
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

  // ===============================================================
  // ON UPGRADE — MIGRAZIONI ORIGINALI
  // ===============================================================

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
      await db.execute("ALTER TABLE movimenti ADD COLUMN searchMetodoPagamento TEXT;");
      await db.execute("""
        UPDATE movimenti SET
          searchCategoria = LOWER(categoria),
          searchDescrizione = LOWER(descrizione),
          searchPuntoVendita = LOWER(puntoVendita),
          searchMetodoPagamento = LOWER(metodoPagamento)
      """);
    }

    if (oldVersion < 11) {
      await db.rawQuery('''
        UPDATE movimenti
        SET data = datetime(data / 1000, 'unixepoch')
        WHERE typeof(data) = 'integer';
      ''');
    }

    if (oldVersion < 13) {
      await db.execute("ALTER TABLE movimenti ADD COLUMN articoli TEXT;");
    }
  }

  // ===============================================================
  // SEED DATABASE — MACROAREE, CATEGORIE, DESCRIZIONI, METODI, PV
  // ===============================================================

  Future<void> seedDatabase(Database db) async {
    // -------------------------------------------------------------
    // SEED MACROAREE (50-30-20)
    // -------------------------------------------------------------
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

    // -------------------------------------------------------------
    // SEED CATEGORIE
    // -------------------------------------------------------------
    final countCat = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categorie'),
    );

    if (countCat == 0) {
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

    // -------------------------------------------------------------
    // SEED DESCRIZIONI
    // -------------------------------------------------------------
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

    // -------------------------------------------------------------
    // SEED METODI DI PAGAMENTO
    // -------------------------------------------------------------
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

    // -------------------------------------------------------------
    // SEED PUNTI VENDITA
    // -------------------------------------------------------------
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

  // ===============================================================
  // SEZIONE 2 — NORMALIZZAZIONI + UTILITY
  // ===============================================================

  String normalizeSmart(String input) {
    if (input.trim().isEmpty) return "";

    String cleaned = input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    cleaned = cleaned.split(" ").map((word) {
      if (word.length <= 2) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    }).join(" ");

    return cleaned;
  }

  String normalizeSearch(String input) {
    if (input.trim().isEmpty) return "";

    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String formatEuro(double value) {
    final formatter = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  double parseEuroToDouble(String input) {
    if (input.trim().isEmpty) return 0.0;

    String cleaned = input.trim();
    cleaned = cleaned.replaceAll('.', '');
    cleaned = cleaned.replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

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
        canonical[norm] = id;
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

  // ===============================================================
  // SEZIONE 3 — FUNZIONI DI VERIFICA
  // ===============================================================

  Future<bool> categoriaEsiste(String nome, MovimentoTipo tipo) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    final res = await db.query(
      'categorie',
      where: 'LOWER(nome) = ? AND tipo = ?',
      whereArgs: [nome.toLowerCase(), tipoString],
      limit: 1,
    );

    return res.isNotEmpty;
  }

  Future<bool> descrizioneEsiste({
    required MovimentoTipo tipo,
    required String categoria,
    required String descrizione,
  }) async {
    final db = await database;

    final res = await db.query(
      'descrizioni',
      where: 'tipo = ? AND LOWER(categoria) = ? AND LOWER(descrizione) = ?',
      whereArgs: [
        tipo.name,
        categoria.toLowerCase(),
        descrizione.toLowerCase(),
      ],
      limit: 1,
    );

    return res.isNotEmpty;
  }

  Future<bool> metodoPagamentoEsiste(String nome) async {
    final db = await database;

    final res = await db.query(
      'metodi_pagamento',
      where: 'LOWER(nome) = ?',
      whereArgs: [nome.toLowerCase()],
      limit: 1,
    );

    return res.isNotEmpty;
  }

  Future<bool> puntoVenditaEsiste(String nome) async {
    final db = await database;

    final res = await db.query(
      'punti_vendita',
      where: 'LOWER(nome) = ?',
      whereArgs: [nome.toLowerCase()],
      limit: 1,
    );

    return res.isNotEmpty;
  }

  Future<int?> getIdMacroareaPerCategoria({
    required String categoria,
    required MovimentoTipo tipo,
  }) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    final res = await db.query(
      'categorie',
      columns: ['idMacroarea'],
      where: 'LOWER(nome) = ? AND tipo = ?',
      whereArgs: [categoria.toLowerCase(), tipoString],
      limit: 1,
    );

    if (res.isEmpty) return null;

    return res.first['idMacroarea'] as int?;
  }

  // ===============================================================
  // SEZIONE 4 — INSERT/UPDATE SAFE PER MOVIMENTI
  // ===============================================================

  Future<InsertResult> insertMovimentoSafe(Movimento m) async {
    final db = await database;

    try {
      if (m.categoria.trim().isEmpty) {
        return const InsertResult(
          success: false,
          errorCode: 'categoria_vuota',
          errorMessage: 'Categoria mancante',
        );
      }

      if (m.descrizione.trim().isEmpty) {
        return const InsertResult(
          success: false,
          errorCode: 'descrizione_vuota',
          errorMessage: 'Descrizione mancante',
        );
      }

      if (m.importo <= 0) {
        return const InsertResult(
          success: false,
          errorCode: 'importo_non_valido',
          errorMessage: 'Importo non valido',
        );
      }

      final catOk = await categoriaEsiste(m.categoria, m.tipo);
      if (!catOk) {
        return InsertResult(
          success: false,
          errorCode: 'categoria_non_esistente',
          errorMessage: 'Categoria non trovata nel vocabolario',
          movimento: m,
        );
      }

      int? idMacroarea;
      if (m.tipo == MovimentoTipo.uscita) {
        idMacroarea = await getIdMacroareaPerCategoria(
          categoria: m.categoria,
          tipo: m.tipo,
        );

        if (idMacroarea == null) {
          return InsertResult(
            success: false,
            errorCode: 'macroarea_non_trovata',
            errorMessage: 'Macroarea non trovata per la categoria selezionata',
            movimento: m,
          );
        }
      }

      final map = m.toMap();

      map['categoria'] = m.categoria;
      map['descrizione'] = m.descrizione;

      map['puntoVendita'] = m.puntoVendita != null
          ? normalizeSmart(m.puntoVendita!)
          : null;

      map['metodoPagamento'] = m.metodoPagamento != null
          ? normalizeSmart(m.metodoPagamento!)
          : null;

      map['nota'] = (m.nota != null && m.nota!.trim().isNotEmpty)
          ? normalizeSmart(m.nota!)
          : "";

      map['articoli'] = m.articoli ?? "";
      map['origine'] = m.origine.name;
      map['importo'] = m.importo;
      map['idMacroarea'] = idMacroarea;

      map['searchCategoria'] = normalizeSearch(map['categoria'] ?? "");
      map['searchDescrizione'] = normalizeSearch(map['descrizione'] ?? "");
      map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita'] ?? "");
      map['searchMetodoPagamento'] = normalizeSearch(map['metodoPagamento'] ?? "");

      map['dataCreazione'] ??= DateTime.now().toIso8601String();

      await db.insert(
        'movimenti',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return InsertResult(
        success: true,
        movimento: m,
      );
    } catch (e) {
      print('ERROR insertMovimentoSafe: $e');
      return InsertResult(
        success: false,
        errorCode: 'eccezione_generica',
        errorMessage: 'Errore inatteso durante il salvataggio',
        movimento: m,
      );
    }
  }

  Future<InsertResult> updateMovimentoSafe(Movimento m) async {
    final db = await database;

    if (m.id == null) {
      return const InsertResult(
        success: false,
        errorCode: 'id_mancante',
        errorMessage: 'ID movimento mancante per l\'aggiornamento',
      );
    }

    try {
      final catOk = await categoriaEsiste(m.categoria, m.tipo);
      if (!catOk) {
        return InsertResult(
          success: false,
          errorCode: 'categoria_non_esistente',
          errorMessage: 'Categoria non trovata nel vocabolario',
          movimento: m,
        );
      }

      int? idMacroarea;
      if (m.tipo == MovimentoTipo.uscita) {
        idMacroarea = await getIdMacroareaPerCategoria(
          categoria: m.categoria,
          tipo: m.tipo,
        );
      }

      final map = m.toMap();

      map['categoria'] = m.categoria;
      map['descrizione'] = m.descrizione;
      map['puntoVendita'] = m.puntoVendita != null
          ? normalizeSmart(m.puntoVendita!)
          : null;
      map['metodoPagamento'] = m.metodoPagamento != null
          ? normalizeSmart(m.metodoPagamento!)
          : null;
      map['nota'] = (m.nota != null && m.nota!.trim().isNotEmpty)
          ? normalizeSmart(m.nota!)
          : "";
      map['articoli'] = m.articoli ?? "";
      map['origine'] = m.origine.name;
      map['importo'] = m.importo;
      map['idMacroarea'] = idMacroarea;

      map['searchCategoria'] = normalizeSearch(map['categoria'] ?? "");
      map['searchDescrizione'] = normalizeSearch(map['descrizione'] ?? "");
      map['searchPuntoVendita'] = normalizeSearch(map['puntoVendita'] ?? "");
      map['searchMetodoPagamento'] = normalizeSearch(map['metodoPagamento'] ?? "");

      final count = await db.update(
        'movimenti',
        map,
        where: 'id = ?',
        whereArgs: [m.id],
      );

      if (count == 0) {
        return InsertResult(
          success: false,
          errorCode: 'movimento_non_trovato',
          errorMessage: 'Nessun movimento aggiornato',
          movimento: m,
        );
      }

      return InsertResult(
        success: true,
        movimento: m,
      );
    } catch (e) {
      print('ERROR updateMovimentoSafe: $e');
      return InsertResult(
        success: false,
        errorCode: 'eccezione_generica',
        errorMessage: 'Errore inatteso durante l\'aggiornamento',
        movimento: m,
      );
    }
  }

  // ===============================================================
  // SEZIONE 5 — WRAPPER PUBBLICI COMPATIBILI
  // ===============================================================

  Future<int> insertMovimento(Movimento m) async {
    final result = await insertMovimentoSafe(m);

    if (!result.success) {
      throw Exception(
        result.errorMessage ??
            'Errore durante l\'inserimento del movimento (${result.errorCode ?? 'errore_sconosciuto'})',
      );
    }

    return 1;
  }

  Future<int> updateMovimento(Movimento m) async {
    final result = await updateMovimentoSafe(m);

    if (!result.success) {
      throw Exception(
        result.errorMessage ??
            'Errore durante l\'aggiornamento del movimento (${result.errorCode ?? 'errore_sconosciuto'})',
      );
    }

    return 1;
  }

  // ===============================================================
  // SEZIONE 6 — VOCABOLARI
  // ===============================================================

  // CATEGORIE

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

    return res.map((r) => r['nome'] as String).toList();
  }

  Future<void> insertCategoria({
    required MovimentoTipo tipo,
    required String nome,
    required int idMacroarea,
  }) async {
    final db = await database;

    await db.insert(
      'categorie',
      {
        'nome': normalizeSmart(nome),
        'tipo': tipo == MovimentoTipo.entrata ? 'entrata' : 'uscita',
        'idMacroarea': idMacroarea,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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

  Future<List<String>> getCategoriePredittive({
    required MovimentoTipo tipo,
  }) async {
    final db = await database;

    final tipoString = tipo == MovimentoTipo.entrata ? "entrata" : "uscita";

    final usate = await db.rawQuery('''
      SELECT categoria, COUNT(*) AS freq
      FROM movimenti
      WHERE tipo = ?
      GROUP BY categoria
      ORDER BY freq DESC
    ''', [tipoString]);

    final usateList = usate.map((e) => e['categoria'] as String).toList();

    final tutte = await db.rawQuery('''
      SELECT nome
      FROM categorie
      WHERE tipo = ?
      ORDER BY nome ASC
    ''', [tipoString]);

    final tutteList = tutte.map((e) => e['nome'] as String).toList();

    return [
      ...usateList,
      ...tutteList.where((c) => !usateList.contains(c)),
    ];
  }

  // DESCRIZIONI

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
/// Compatibilità con la UI esistente
  Future<void> aggiungiDescrizione({
    required MovimentoTipo tipo,
    required String categoria,
    required String descrizione,
  }) async {
  await insertDescrizione(
    tipo: tipo,
    categoria: categoria,
    descrizione: descrizione,
  );
}

  Future<List<String>> getDescrizioniPredittive({
    required MovimentoTipo tipo,
    required String categoria,
  }) async {
    final db = await database;

    final usate = await db.rawQuery('''
      SELECT descrizione, COUNT(*) AS freq
      FROM movimenti
      WHERE tipo = ? AND categoria = ?
      GROUP BY descrizione
      ORDER BY freq DESC
    ''', [tipo.name, categoria]);

    final usateList = usate.map((e) => e['descrizione'] as String).toList();

    final tutte = await db.query(
      'descrizioni',
      columns: ['descrizione'],
      where: 'tipo = ? AND categoria = ?',
      whereArgs: [tipo.name, categoria],
      orderBy: 'descrizione ASC',
    );

    final tutteList = tutte.map((e) => e['descrizione'] as String).toList();

    return [
      ...usateList,
      ...tutteList.where((d) => !usateList.contains(d)),
    ];
  }

  // METODI DI PAGAMENTO

  Future<List<String>> getMetodiPagamento() async {
    final db = await database;

    final res = await db.query(
      'metodi_pagamento',
      orderBy: 'LOWER(nome) ASC',
    );

    return res.map((e) => e['nome'] as String).toList();
  }

/// Compatibilità con la UI esistente
  Future<List<String>> getMetodiPagamentoListaCompleta() async {
    return getMetodiPagamento();
  }
/// Compatibilità con la UI esistente
  Future<List<String>> getMetodiPagamentoFiltrati(String filtro) async {
    final lista = await getMetodiPagamento();
    final f = filtro.trim().toLowerCase();
    return lista.where((m) => m.toLowerCase().contains(f)).toList();
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

  /// Compatibilità con la UI esistente
  Future<void> aggiungiMetodoPagamento(String nome) async {
    await insertMetodoPagamento(nome);
  }

  // PUNTI VENDITA

  Future<List<String>> getPuntiVenditaListaCompleta() async {
    final db = await database;

    final res = await db.query(
      'punti_vendita',
      orderBy: 'LOWER(nome) ASC',
    );

    return res.map((e) => e['nome'] as String).toList();
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

  //NOTE - AUTOCOMPLETE
  Future<List<String>> getNoteUsate() async {
    final db = await database;

    final res = await db.rawQuery('''
    SELECT DISTINCT nota
    FROM movimenti
    WHERE nota IS NOT NULL AND TRIM(nota) <> ''
    ORDER BY nota ASC
  ''');

    return res.map((e) => e['nota'] as String).toList();
  }

  // ===============================================================
  // SEZIONE 7 — MOVIMENTI, RICERCA, DASHBOARD, PREDITTIVI
  // ===============================================================

  // MOVIMENTI — CRUD BASE

  Future<List<Movimento>> getMovimenti() async {
    final db = await database;

    final res = await db.query(
      'movimenti',
      orderBy: 'data DESC',
    );

    return res.map((e) => Movimento.fromMap(e)).toList();
  }

  Future<int> deleteMovimento(int id) async {
    final db = await database;

    return await db.delete(
      'movimenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // RICERCA GOOGLE-LIKE

  Future<List<Movimento>> searchMovimentiGoogle(String query) async {
    final db = await database;

    final cleaned = normalizeSearch(query);

    if (cleaned.isEmpty) {
      return getMovimenti();
    }

    final tokens = cleaned.split(' ');

    final whereClauses = <String>[];
    final whereArgs = <String>[];

    for (final token in tokens) {
      whereClauses.add('''
        (
          searchCategoria LIKE ? OR
          searchDescrizione LIKE ? OR
          searchPuntoVendita LIKE ? OR
          searchMetodoPagamento LIKE ?
        )
      ''');

      whereArgs.addAll([
        '%$token%',
        '%$token%',
        '%$token%',
        '%$token%',
      ]);
    }

    final whereString = whereClauses.join(' AND ');

    final res = await db.query(
      'movimenti',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'data DESC',
    );

    return res.map((e) => Movimento.fromMap(e)).toList();
  }

  // DASHBOARD 50-30-20

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

  Future<Map<String, double>> getUscitePerMacroarea(
    int year,
    int month,
  ) async {
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
      final totale =
          row['totale'] == null ? 0.0 : (row['totale'] as num).toDouble();

      final nome = macro.firstWhere((m) => m['id'] == id)['nome'] as String;

      result[nome] = totale;
    }

    return result;
  }
}