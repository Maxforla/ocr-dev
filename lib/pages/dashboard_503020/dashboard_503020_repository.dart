import 'package:sqflite/sqflite.dart';
import 'package:spese_app/utils/database_helper.dart';


class Macroarea {
  final int id;
  final String nome;
  final double percentuale;

  Macroarea({
    required this.id,
    required this.nome,
    required this.percentuale,
  });
}

class DashboardData {
  final double totaleEntrate;
  final double totaleUscite;
  final Map<int, double> spesePerMacroarea;

  DashboardData({
    required this.totaleEntrate,
    required this.totaleUscite,
    required this.spesePerMacroarea,
  });
}

abstract class Dashboard503020Repository {
  Future<List<String>> getMesiDisponibili();
  Future<List<Macroarea>> getMacroaree();
  Future<void> updatePercentualeMacroarea(int id, double percentuale);
  Future<DashboardData> getDashboardData({String? mese});
}

class Dashboard503020RepositoryImpl implements Dashboard503020Repository {
  final dbHelper = DatabaseHelper.instance;

  @override
  Future<List<String>> getMesiDisponibili() async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y-%m', data) AS mese
      FROM movimenti
      ORDER BY mese DESC
    ''');

    return result.map((row) => row['mese'] as String).toList();
  }

  @override
  Future<List<Macroarea>> getMacroaree() async {
    final db = await dbHelper.database;

    final result = await db.query('macroaree');

    return result.map((row) {
      return Macroarea(
        id: row['id'] as int,
        nome: row['nome'] as String,
        percentuale: (row['percentuale'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<void> updatePercentualeMacroarea(int id, double percentuale) async {
    final db = await dbHelper.database;

    await db.update(
      'macroaree',
      {'percentuale': percentuale},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<DashboardData> getDashboardData({String? mese}) async {
    final db = await dbHelper.database;

    String whereEntrate = "tipo = 'entrata'";
    String whereUscite = "tipo = 'uscita'";
    String whereMacro = "idMacroarea = ?";

    List<String> whereArgsEntrate = [];
    List<String> whereArgsUscite = [];
    List<String> whereArgsMacro = [];

    if (mese != null) {
      whereEntrate += " AND strftime('%Y-%m', data) = ?";
      whereUscite += " AND strftime('%Y-%m', data) = ?";
      whereArgsEntrate.add(mese);
      whereArgsUscite.add(mese);
    }

    final entrate = await db.rawQuery(
      "SELECT SUM(importo) AS tot FROM movimenti WHERE $whereEntrate",
      whereArgsEntrate,
    );

    final uscite = await db.rawQuery(
      "SELECT SUM(importo) AS tot FROM movimenti WHERE $whereUscite",
      whereArgsUscite,
    );

    final totaleEntrate =
        (entrate.first['tot'] as num?)?.toDouble() ?? 0.0;
    final totaleUscite =
        (uscite.first['tot'] as num?)?.toDouble() ?? 0.0;

    // Spese per macroarea
    final macroaree = await getMacroaree();
    final Map<int, double> spesePerMacroarea = {};

    for (final m in macroaree) {
      String where = "tipo = 'uscita' AND idMacroarea = ?";
      List<String> args = ["${m.id}"];

      if (mese != null) {
        where += " AND strftime('%Y-%m', data) = ?";
        args.add(mese);
      }

      final res = await db.rawQuery(
        "SELECT SUM(importo) AS tot FROM movimenti WHERE $where",
        args,
      );

      spesePerMacroarea[m.id] =
          (res.first['tot'] as num?)?.toDouble() ?? 0.0;
    }

    return DashboardData(
      totaleEntrate: totaleEntrate,
      totaleUscite: totaleUscite,
      spesePerMacroarea: spesePerMacroarea,
    );
  }
}