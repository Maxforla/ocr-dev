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
  final OrigineDati origine;

  final String searchCategoria;
  final String searchDescrizione;
  final String searchPuntoVendita;
  final String searchMetodoPagamento;   // ⭐ NUOVO CAMPO

  final DateTime dataCreazione;

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
    required this.origine,
    this.searchCategoria = "",
    this.searchDescrizione = "",
    this.searchPuntoVendita = "",
    this.searchMetodoPagamento = "",     // ⭐ NUOVO CAMPO
    required this.dataCreazione,
  });

  factory Movimento.fromMap(Map<String, dynamic> map) {
    return Movimento(
      id: map['id'] as int?,
      tipo: MovimentoTipo.values.firstWhere((e) => e.name == map['tipo']),
      data: DateTime.fromMillisecondsSinceEpoch(map['data']),
      categoria: map['categoria'] ?? "",
      descrizione: map['descrizione'] ?? "",
      importo: (map['importo'] as num).toDouble(),
      puntoVendita: map['puntoVendita'] ?? "",
      metodoPagamento: map['metodoPagamento'] ?? "",
      nota: map['nota'],
      origine: OrigineDati.values.firstWhere(
        (e) => e.name == (map['origine'] ?? 'manuale'),
        orElse: () => OrigineDati.manuale,
      ),
      searchCategoria: map['searchCategoria'] ?? "",
      searchDescrizione: map['searchDescrizione'] ?? "",
      searchPuntoVendita: map['searchPuntoVendita'] ?? "",
      searchMetodoPagamento: map['searchMetodoPagamento'] ?? "",   // ⭐ NUOVO CAMPO
      dataCreazione: map['dataCreazione'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCreazione'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'data': data.millisecondsSinceEpoch,
      'categoria': categoria,
      'descrizione': descrizione,
      'importo': importo,
      'puntoVendita': puntoVendita,
      'metodoPagamento': metodoPagamento,
      'nota': nota,
      'origine': origine.name,
      'searchCategoria': searchCategoria,
      'searchDescrizione': searchDescrizione,
      'searchPuntoVendita': searchPuntoVendita,
      'searchMetodoPagamento': searchMetodoPagamento,   // ⭐ NUOVO CAMPO
      'dataCreazione': dataCreazione.millisecondsSinceEpoch,
    };
  }
}