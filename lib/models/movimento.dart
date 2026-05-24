enum MovimentoTipo { uscita, entrata }
enum OrigineDati { manuale, ocr }

class Movimento {
  final int? id;
  final MovimentoTipo tipo;
  final DateTime data;
  final String categoria;
  final String descrizione;
  final double importo;
  final String puntoVendita;
  final String metodoPagamento;
  final String? nota;
  final String? articoli;
  final OrigineDati origine;

  // 🔥 RESI NULLABLE
  final String? searchCategoria;
  final String? searchDescrizione;
  final String? searchPuntoVendita;
  final String? searchMetodoPagamento;

  final DateTime dataCreazione;
  final int? idMacroarea;

  Movimento({
    this.id,
    required this.tipo,
    required this.data,
    required this.categoria,
    required this.descrizione,
    required this.importo,
    required this.puntoVendita,
    required this.metodoPagamento,
    this.nota,
    this.articoli,
    required this.origine,

    // 🔥 DEFAULT SICURI
    this.searchCategoria,
    this.searchDescrizione,
    this.searchPuntoVendita,
    this.searchMetodoPagamento,

    required this.dataCreazione,
    this.idMacroarea,
  });

  factory Movimento.fromMap(Map<String, dynamic> map) {
    return Movimento(
      id: map['id'] as int?,
      tipo: MovimentoTipo.values.firstWhere((e) => e.name == map['tipo']),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'] ?? "",
      descrizione: map['descrizione'] ?? "",
      importo: (map['importo'] as num).toDouble(),
      puntoVendita: map['puntoVendita'] ?? "",
      metodoPagamento: map['metodoPagamento'] ?? "",
      nota: map['nota'],
      articoli: map['articoli'],
      origine: OrigineDati.values.firstWhere(
        (e) => e.name == (map['origine'] ?? 'manuale'),
        orElse: () => OrigineDati.manuale,
      ),

      // 🔥 SEMPRE STRINGA
      searchCategoria: map['searchCategoria'] ?? "",
      searchDescrizione: map['searchDescrizione'] ?? "",
      searchPuntoVendita: map['searchPuntoVendita'] ?? "",
      searchMetodoPagamento: map['searchMetodoPagamento'] ?? "",

      dataCreazione: (() {
        final v = map['dataCreazione'];
        if (v == null) return DateTime.now();
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        if (v is String) {
          try { return DateTime.parse(v); } catch (_) {}
        }
        return DateTime.now();
      })(),

      idMacroarea: map['idMacroarea'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'data': data.toIso8601String(),
      'categoria': categoria,
      'descrizione': descrizione,
      'importo': importo,
      'puntoVendita': puntoVendita,
      'metodoPagamento': metodoPagamento,
      'nota': nota,
      'articoli': articoli,
      'origine': origine.name,

      // 🔥 SEMPRE STRINGA
      'searchCategoria': searchCategoria ?? "",
      'searchDescrizione': searchDescrizione ?? "",
      'searchPuntoVendita': searchPuntoVendita ?? "",
      'searchMetodoPagamento': searchMetodoPagamento ?? "",

      'dataCreazione': dataCreazione.toIso8601String(),
    };
  }
}