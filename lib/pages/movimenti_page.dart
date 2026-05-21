import 'package:flutter/material.dart';
import '../models/movimento.dart';
import 'package:spese_app/utils/database_helper.dart';

import 'dettaglio_movimento_page.dart';
import '../services/ocr_service.dart';
import '../services/ocr_parser.dart';
import '../services/ocr_flow.dart';
import 'nuovo_movimento_page.dart';
import '../utils/normalize_smart.dart';
import 'package:spese_app/utils/format_euro.dart';
import 'dart:async';

class MovimentiPage extends StatefulWidget {
  const MovimentiPage({super.key});

  @override
  _MovimentiPageState createState() => _MovimentiPageState();
}

class _MovimentiPageState extends State<MovimentiPage> {
  List<Movimento> movimenti = [];

  // FILTRI
  String filtro = "tutti";
  String query = "";
  String meseSelezionato = "Riepilogo generale";
  // RICERCA
  final TextEditingController _searchController = TextEditingController();

  // ⭐⭐⭐ VARIABILI DI STATO PER LA RICERCA "ALLA GOOGLE" ⭐⭐⭐
  Timer? _debounce;
  List<Movimento> _risultati = [];
  String _query = "";

  @override
  void initState() {
    super.initState();
    _caricaMovimenti();
  }

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _caricaMovimenti();   // ricarica sempre i movimenti dal DB
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _caricaMovimenti() async {
  final lista = await DatabaseHelper.instance.getMovimenti();

  // 🔥 Ordina per data decrescente (più recenti in alto)
  lista.sort((a, b) => b.data.compareTo(a.data));

  setState(() {
    movimenti = lista;
    _risultati = lista;   // ⭐ inizializza anche la lista visibile
  });
}

// ⭐⭐⭐ INCOLLA QUI LA FUNZIONE DI RICERCA ⭐⭐⭐

void _onSearchChanged(String value) {
  _query = value;

  // Cancella eventuale timer precedente
  _debounce?.cancel();

  // Avvia un nuovo debounce
  _debounce = Timer(const Duration(milliseconds: 300), () async {
    if (_query.trim().isEmpty) {
      // Se la query è vuota → ricarica tutti i movimenti
      _risultati = await DatabaseHelper.instance.getMovimenti();
    } else {
      // Altrimenti → ricerca alla Google
      _risultati = await DatabaseHelper.instance.searchMovimentiGoogle(_query);
    }

    setState(() {});
  });
}



  Future<void> _scanReceipt() async {
    try {
      final ocr = OcrService();
      final parser = OcrParser();

      // 1) Scatta la foto
      final image = await ocr.takePhoto();
      if (image == null) {
        print("Nessuna immagine selezionata");
        return;
      }

      // 2) Estrai testo grezzo
      final rawText = await ocr.extractText(image);
      if (rawText.isEmpty) {
        debugPrint("OCR fallito o testo vuoto");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossibile leggere lo scontrino")),
        );
        return;
      }

      print("TESTO OCR:");
      print(rawText);

      // 3) Parsing intelligente
      final parsed = await parser.parse(rawText);

      print("IMPORTO TROVATO: ${parsed.importo}");
      print("DATA TROVATA: ${parsed.data}");
      print("PUNTO VENDITA: ${parsed.puntoVendita}");
      print("CATEGORIA: ${parsed.categoria}");
      print("DESCRIZIONE: ${parsed.descrizione}");
      print("METODO PAGAMENTO: ${parsed.metodoPagamento}");

      // 4) Nota OCR pulita
      final notaPulita = parser.pulisciNotaOCR(rawText);

      // 5) Movimento precompilato
      final nuovoMovimento = Movimento(
        id: null,
        tipo: MovimentoTipo.uscita,
        data: parsed.data ?? DateTime.now(),
        categoria: parsed.categoria ?? "Da scontrino",
        descrizione: parsed.descrizione ?? "Spesa rilevata da OCR",
        importo: parsed.importo ?? 0.0,
        puntoVendita: parsed.puntoVendita ?? "",
        metodoPagamento: parsed.metodoPagamento ?? "",
        nota: notaPulita,
        origine: OrigineDati.ocr,
        searchCategoria: normalizeSmart(parsed.categoria ?? "Da scontrino"),
        searchDescrizione: normalizeSmart(parsed.descrizione ?? "Spesa rilevata da OCR"),
        searchPuntoVendita: normalizeSmart(parsed.puntoVendita ?? ""),
        dataCreazione: DateTime.now(),
        idMacroarea: 0,
      );


      // 6) Vai alla pagina di dettaglio per conferma
      // 6) Logica intelligente: salvo subito se il movimento è completo
      bool completo =
          (parsed.importo != null) &&
              (parsed.data != null) &&
              (parsed.categoria != null) &&
              (parsed.descrizione != null);

// Se completo → salvo subito
      if (completo) {
        await DatabaseHelper.instance.insertMovimento(nuovoMovimento);
        _caricaMovimenti();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Movimento salvato automaticamente"),
              duration: Duration(seconds: 2),
            ),
          );
        });


        return; // Fine, non apro la pagina di modifica
      }

// 7) Altrimenti apro la pagina di modifica
      final risultato = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DettaglioMovimentoPage(movimento: nuovoMovimento),
        ),
      );

      if (risultato is Movimento) {
        await DatabaseHelper.instance.insertMovimento(risultato);
        _caricaMovimenti();
      }

    } catch (e) {
      print("ERRORE OCR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore durante la scansione OCR"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // NOMI MESI
  String _nomeMese(int m) {
    const mesi = [
      "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
      "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"
    ];
    return mesi[m - 1];
  }

  int _numeroMese(String nome) {
    const mesi = {
      "Gennaio": 1, "Febbraio": 2, "Marzo": 3, "Aprile": 4, "Maggio": 5, "Giugno": 6,
      "Luglio": 7, "Agosto": 8, "Settembre": 9, "Ottobre": 10, "Novembre": 11, "Dicembre": 12
    };
    return mesi[nome]!;
  }

  // RAGGRUPPA MOVIMENTI PER MESE
  Map<String, List<Movimento>> _raggruppaPerMese(List<Movimento> lista) {
    final Map<String, List<Movimento>> mappa = {};

    for (var m in lista) {
      final key = "${_nomeMese(m.data.month)} ${m.data.year}";
      mappa.putIfAbsent(key, () => []);
      mappa[key]!.add(m);
    }

    final sortedKeys = mappa.keys.toList()
      ..sort((a, b) {
        final pa = a.split(" ");
        final pb = b.split(" ");
        final ma = _numeroMese(pa[0]);
        final mb = _numeroMese(pb[0]);
        final ya = int.parse(pa[1]);
        final yb = int.parse(pb[1]);
        return DateTime(yb, mb).compareTo(DateTime(ya, ma));
      });

    final Map<String, List<Movimento>> ordinata = {};
    for (var k in sortedKeys) {
      final listaMese = mappa[k]!;
      listaMese.sort((a, b) => b.data.compareTo(a.data));
      ordinata[k] = listaMese;
    }

    return ordinata;
  }
  // ANIMAZIONE CARD
  Widget _animatedCard({
    required int index,
    required Widget child,
  }) {
    final delay = Duration(milliseconds: 60 * index);
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final start = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: start ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  // EVIDENZIAZIONE TESTO NELLA RICERCA
  Widget _highlightText(
      String text,
      String query, {
        TextStyle? normalStyle,
        TextStyle? highlightStyle,
        int maxLines = 1,
        bool softWrap = false,
      }) {
    normalStyle ??= const TextStyle(fontSize: 13);
    highlightStyle ??= TextStyle(
      fontSize: normalStyle.fontSize,
      fontWeight: FontWeight.w700,
      color: Colors.blue.shade900,
      backgroundColor: Colors.blue.shade100,
    );

    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        softWrap: softWrap,
        overflow: TextOverflow.fade,
        style: normalStyle,
      );
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + q.length),
        style: highlightStyle,
      ));
      start = index + q.length;
    }

    return RichText(
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: TextOverflow.fade,
      text: TextSpan(children: spans),
    );
  }

  // CARD MOVIMENTO
  Widget _cardMovimento(Movimento m, int index) {
    final isEntrata = m.tipo == MovimentoTipo.entrata;

    return _animatedCard(
      index: index,
      child: Dismissible(
        key: ValueKey(m.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Conferma eliminazione"),
              content: const Text("Vuoi davvero eliminare questo movimento?"),
              actions: [
                TextButton(
                  child: const Text("Annulla"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text("Elimina"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          await DatabaseHelper.instance.deleteMovimento(m.id!);
          _caricaMovimenti();
        },
        child: GestureDetector(
          onTap: () async {
            final risultato = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DettaglioMovimentoPage(movimento: m),
              ),
            );

            // 🟥 GESTIONE CANCELLAZIONE DA MOVIMENTI
            if (risultato == "eliminato") {
              await DatabaseHelper.instance.deleteMovimento(m.id!);
              _caricaMovimenti();
              return;
            }

            // 🟩 GESTIONE MODIFICA / DUPLICA
            if (risultato is Movimento) {
              if (risultato.id == null) {
                await DatabaseHelper.instance.insertMovimento(risultato);
              } else {
                await DatabaseHelper.instance.updateMovimento(risultato);
              }
              _caricaMovimenti();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isEntrata ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isEntrata ? Colors.green : Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _highlightText(
                        m.categoria,
                        query,
                        normalStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      if (m.descrizione.isNotEmpty)
                        _highlightText(
                          m.descrizione,
                          query,
                          normalStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      if (m.puntoVendita.isNotEmpty)
                        _highlightText(
                          m.puntoVendita,
                          query,
                          normalStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      euro(m.importo),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEntrata ? Colors.green : Colors.red,
                    ),
                  ),
                    Text(
                      "${m.data.day.toString().padLeft(2, '0')}/"
                          "${m.data.month.toString().padLeft(2, '0')}/"
                          "${m.data.year}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // FILTRI RAPIDI
  Widget _filtroPill(String label, String value) {
    final selected = filtro == value;

    return GestureDetector(
      onTap: () => setState(() => filtro = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.blue.shade900 : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  // RIEPILOGO GENERALE
  Widget _riepilogoGenerale(List<Movimento> lista) {
    double entrate = 0;
    double uscite = 0;
    int movEntrate = 0;
    int movUscite = 0;

    for (var m in lista) {
      if (m.tipo == MovimentoTipo.entrata) {
        entrate += m.importo;
        movEntrate++;
      } else {
        uscite += m.importo;
        movUscite++;
      }
    }

    final saldo = entrate - uscite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text("Entrate totali",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "${euro(entrate)} ($movEntrate)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text("Uscite totali",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "${euro(uscite)} ($movUscite)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Saldo totale: ${euro(saldo)}",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: saldo >= 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Movimenti totali: ${lista.length}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // RIEPILOGO MENSILE
  Widget _riepilogoMensile(List<Movimento> lista, String mese) {
    if (mese == "Riepilogo generale") {
      return _riepilogoGenerale(lista);
    }

    double entrate = 0;
    double uscite = 0;
    int movEntrate = 0;
    int movUscite = 0;

    for (var m in lista) {
      final key = "${_nomeMese(m.data.month)} ${m.data.year}";
      if (key == mese) {
        if (m.tipo == MovimentoTipo.entrata) {
          entrate += m.importo;
          movEntrate++;
        } else {
          uscite += m.importo;
          movUscite++;
        }
      }
    }

    final saldo = entrate - uscite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text("Entrate",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "${euro(entrate)} ($movEntrate)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text("Uscite",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      "${euro(uscite)} ($movUscite)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Saldo: ${DatabaseHelper.instance.formatEuro(saldo)}",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: saldo >= 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // BARRA MESI
  Widget _barraMesi(Map<String, List<Movimento>> mappa) {
    final mesi = ["Riepilogo generale", ...mappa.keys];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mesi.length,
        itemBuilder: (context, index) {
          final mese = mesi[index];
          final selected = meseSelezionato == mese;

          return GestureDetector(
            onTap: () => setState(() => meseSelezionato = mese),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.blue.shade300 : Colors.grey.shade400,
                ),
              ),
              child: Center(
                child: Text(
                  mese,
                  style: TextStyle(
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? Colors.blue.shade900
                        : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // FILTRAGGIO MOVIMENTI
  List<Movimento> _filtraMovimenti() {
    List<Movimento> lista = [..._risultati];

    if (meseSelezionato != "Riepilogo generale") {
      lista = lista.where((m) {
        final key = "${_nomeMese(m.data.month)} ${m.data.year}";
        return key == meseSelezionato;
      }).toList();
    }

    if (filtro == "entrate") {
      lista = lista.where((m) => m.tipo == MovimentoTipo.entrata).toList();
    } else if (filtro == "uscite") {
      lista = lista.where((m) => m.tipo == MovimentoTipo.uscita).toList();
    }

// 🔥 Ordina per data decrescente
  lista.sort((a, b) => b.data.compareTo(a.data));

    return lista;
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final listaFiltrata = _filtraMovimenti();
    final mappaMesi = _raggruppaPerMese(listaFiltrata);


    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Movimenti"),
        actions: []

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _barraMesi(mappaMesi),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Cerca per categoria, descrizione o negozio...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filtroPill("Tutti", "tutti"),
                _filtroPill("Entrate", "entrate"),
                _filtroPill("Uscite", "uscite"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _riepilogoMensile(listaFiltrata, meseSelezionato),
          ),
          Expanded(
            child: listaFiltrata.isEmpty
                ? const Center(
              child: Text(
                "Nessun movimento trovato",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: listaFiltrata.length,
              itemBuilder: (context, index) {
                final m = listaFiltrata[index];

                bool mostraHeader = false;
                if (index == 0) {
                  mostraHeader = true;
                } else {
                  final prev = listaFiltrata[index - 1];
                  final keyPrev =
                      "${_nomeMese(prev.data.month)} ${prev.data.year}";
                  final keyCurr =
                      "${_nomeMese(m.data.month)} ${m.data.year}";
                  if (keyPrev != keyCurr) mostraHeader = true;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mostraHeader)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 12, bottom: 6),
                        child: Text(
                          "${_nomeMese(m.data.month)} ${m.data.year}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    _cardMovimento(m, index),
                  ],
                );
              },
            ),
          ),
        ],
      ),
     floatingActionButton: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         FloatingActionButton(
           heroTag: "camera",
           onPressed: () async {
             final movimento = await OcrFlow.scan(context);
             if (movimento != null) {
               await _caricaMovimenti(); // aggiorna lista e riepiloghi
             }
           },
           child: const Icon(Icons.camera_alt, color: Colors.black),
         ),
         const SizedBox(width: 12),
         FloatingActionButton(
           heroTag: "add",
           onPressed: () async {
             final result = await Navigator.push<Movimento>(
               context,
               MaterialPageRoute(
                 fullscreenDialog: true,
                 builder: (_) => NuovoMovimentoPage(),
               ),
             );

             if (result != null) {
               await DatabaseHelper.instance.insertMovimento(result);
               await _caricaMovimenti();
             }
           },
           child: const Icon(Icons.add, color: Colors.black),
         ),
       ],
     ),





    );
  }
}