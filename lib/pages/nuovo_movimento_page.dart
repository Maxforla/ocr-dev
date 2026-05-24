import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:spese_app/utils/database_helper.dart';

import '../models/movimento.dart';
import '../utils/normalize_smart.dart';
import '../utils/format_importo.dart';
import 'package:spese_app/utils/database_helper.dart';
// 🔥 IMPORT PER OCR (adatta il path se diverso nel tuo progetto)
import 'package:spese_app/services/ocr_parser.dart';

class NuovoMovimentoPage extends StatefulWidget {
  final Movimento? movimentoDaModificare;

  const NuovoMovimentoPage({
    super.key,
    this.movimentoDaModificare,
  });

  @override
  State<NuovoMovimentoPage> createState() => _NuovoMovimentoPageState();
}

class _NuovoMovimentoPageState extends State<NuovoMovimentoPage> {
  String normalizeSearch(String input) {
    if (input.trim().isEmpty) return "";
    String cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  MovimentoTipo _tipo = MovimentoTipo.uscita;
  String? _categoria;
  String? _descrizione;
  String? _metodoPagamento;
  late DateTime _data;

  final _importoController = TextEditingController();
  final _puntoVenditaController = TextEditingController();
  final _notaController = TextEditingController();
  final _articoliController = TextEditingController();

  List<String> _listaPuntiVendita = [];

  // Evidenziazione OCR
  bool ocrCategoria = false;
  bool ocrDescrizione = false;
  bool ocrImporto = false;
  bool ocrPuntoVendita = false;
  bool ocrMetodoPagamento = false;

  @override
  void initState() {
    super.initState();
    _caricaPuntiVendita();

    final m = widget.movimentoDaModificare;

    _data = m?.data ?? DateTime.now();
    _tipo = m?.tipo ?? MovimentoTipo.uscita;

    // OCR: categoria / descrizione / metodo / PdV / importo
    if (m?.categoria != null) {
      _categoria = m!.categoria;
      ocrCategoria = true;
    }

    if (m?.descrizione != null) {
      _descrizione = m!.descrizione;
      ocrDescrizione = true;
    }

    if (m != null && m.metodoPagamento.isNotEmpty) {
      _metodoPagamento = m.metodoPagamento;
      ocrMetodoPagamento = true;
    }

    if (m != null && m.puntoVendita.isNotEmpty) {
      _puntoVenditaController.text = m.puntoVendita;
      ocrPuntoVendita = true;
    }

    if (m?.importo != null && m!.importo > 0) {
      _importoController.text = m.importo.toString();
      ocrImporto = true;
    }

    _notaController.text = m?.nota ?? '';
    _articoliController.text = m?.articoli ?? '';
  }

  String _formatData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _caricaPuntiVendita() async {
    final lista = await DatabaseHelper.instance.getPuntiVenditaListaCompleta();

    // Ordina alfabeticamente i punti vendita
    lista.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      _listaPuntiVendita = lista;
    });
  }

  // 🔍 FUNZIONE DI DEBUG OCR
  void debugOCR(String testo) async {
    final parser = OcrParser();
    final r = await parser.parse(testo);

    print("=== DEBUG OCR ===");
    print("PdV: ${r.puntoVendita}");
    print("Categoria: ${r.categoria}");
    print("Descrizione: ${r.descrizione}");
    print("Metodo: ${r.metodoPagamento}");
    print("Note: ${r.testoGrezzo}");
    print("=================");
  }

  Future<void> _scegliData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  Future<int?> _scegliMacroarea() async {
    final db = await DatabaseHelper.instance.database;

    final macroaree = await db.query('macroaree');

    return showDialog<int>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Scegli macroarea"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: macroaree.map((m) {
              return ListTile(
                title: Text(m['nome'].toString()),
                onTap: () => Navigator.pop(context, m['id'] as int),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo movimento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _salva,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------------------------
            // CARD: TIPO MOVIMENTO
            // -------------------------
            _buildCard(
              title: "Tipo di movimento",
              child: DropdownButtonFormField<MovimentoTipo>(
                value: _tipo,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: MovimentoTipo.uscita, child: Text('Uscita')),
                  DropdownMenuItem(
                      value: MovimentoTipo.entrata, child: Text('Entrata')),
                ],
                onChanged: (v) {
                  setState(() {
                    _tipo = v!;
                    _categoria = null;
                    _descrizione = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: DATA
            // -------------------------
            _buildCard(
              title: "Data",
              child: InkWell(
                onTap: _scegliData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatData(_data)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: CATEGORIA
            // -------------------------
            _buildCard(
              title: "Categoria",
              highlight: ocrCategoria,
              child: FutureBuilder<List<String>>(
                future: DatabaseHelper.instance.getCategorieByTipo(_tipo),
                builder: (_, snapshot) {
                  final categorie = snapshot.data ?? [];

                  // Ordina alfabeticamente le categorie
                  categorie.sort(
                      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                  final items = [...categorie, "__nuova__"];

                  return DropdownSearch<String>(
                    items: items,
                    selectedItem: _categoria,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      itemBuilder: (context, item, isSelected) {
                        if (item == "__nuova__") {
                          return const ListTile(
                            leading: Icon(Icons.add, color: Colors.blue),
                            title: Text("Aggiungi nuova categoria"),
                          );
                        }
                        return ListTile(title: Text(item));
                      },
                      searchFieldProps: TextFieldProps(),
                    ),
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    dropdownBuilder: (context, selectedItem) {
                      if (selectedItem == "__nuova__") {
                        return const Text("Aggiungi nuova categoria");
                      }
                      return Text(selectedItem ?? "");
                    },
                    onChanged: _onCategoriaChanged,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: DESCRIZIONE
            // -------------------------
            if (_categoria != null)
              _buildCard(
                title: "Descrizione",
                highlight: ocrDescrizione,
                child: FutureBuilder<List<String>>(
                  future: DatabaseHelper.instance.getDescrizioniPredittive(
                    tipo: _tipo,
                    categoria: _categoria!,
                  ),
                  builder: (_, snapshot) {
                    final descrizioni = snapshot.data ?? [];
                    // Ordina alfabeticamente le descrizioni
                    descrizioni.sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                    final items = [...descrizioni, "__nuova__"];

                    return DropdownSearch<String>(
                      items: items,
                      selectedItem: _descrizione,
                      // evita duplicati quando la descrizione ha 2+ parole
                      compareFn: (a, b) => a == b,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (context, item, isSelected) {
                          if (item == "__nuova__") {
                            return const ListTile(
                              leading: Icon(Icons.add, color: Colors.blue),
                              title: Text("Aggiungi nuova descrizione"),
                            );
                          }
                          return ListTile(title: Text(item));
                        },
                        searchFieldProps: TextFieldProps(),
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      dropdownBuilder: (context, selectedItem) {
                        if (selectedItem == "__nuova__") {
                          return const Text("Aggiungi nuova descrizione");
                        }
                        return Text(selectedItem ?? "");
                      },
                      onChanged: _onDescrizioneChanged,
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: IMPORTO
            // -------------------------
            _buildCard(
              title: "Importo",
              highlight: ocrImporto,
              child: TextField(
                controller: _importoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "0.00",
                ),
                onEditingComplete: () {
                  final v = _importoController.text;
                  final formatted = formatImportoRealtime(v);

                  _importoController.value =
                      _importoController.value.copyWith(
                    text: formatted,
                    selection:
                        TextSelection.collapsed(offset: formatted.length),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: PUNTO VENDITA
            // -------------------------
            _buildCard(
              title: "Luogo / Soggetto",
              highlight: ocrPuntoVendita,
              child: DropdownSearch<String>(
                items: [
                  ..._listaPuntiVendita,
                  "__nuovo__",
                ],
                selectedItem: _puntoVenditaController.text.isEmpty
                    ? null
                    : _puntoVenditaController.text,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isSelected) {
                    if (item == "__nuovo__") {
                      return const ListTile(
                        leading: Icon(Icons.add, color: Colors.blue),
                        title: Text("Aggiungi nuovo punto vendita"),
                      );
                    }
                    return ListTile(title: Text(item));
                  },
                  searchFieldProps: TextFieldProps(),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                dropdownBuilder: (context, selectedItem) {
                  if (selectedItem == "__nuovo__") {
                    return const Text("Aggiungi nuovo punto vendita");
                  }
                  return Text(selectedItem ?? "");
                },
                onChanged: _onPuntoVenditaChanged,
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: METODO PAGAMENTO
            // -------------------------
            _buildCard(
              title: "Metodo di pagamento",
              highlight: ocrMetodoPagamento,
              child: DropdownSearch<String>(
                asyncItems: (String filtro) async {
                  List<String> lista;
                  if (filtro.isEmpty) {
                    lista = await DatabaseHelper.instance
                        .getMetodiPagamentoListaCompleta();
                  } else {
                    lista = await DatabaseHelper.instance
                        .getMetodiPagamentoFiltrati(filtro);
                  }

                  // Ordina alfabeticamente i metodi di pagamento
                  lista.sort(
                      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                  return [...lista, "__nuovo__"];
                },
                selectedItem:
                    _metodoPagamento?.isEmpty ?? true ? null : _metodoPagamento,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isSelected) {
                    if (item == "__nuovo__") {
                      return const ListTile(
                        leading: Icon(Icons.add, color: Colors.blue),
                        title: Text("Aggiungi nuovo metodo di pagamento"),
                      );
                    }
                    return ListTile(title: Text(item));
                  },
                  searchFieldProps: TextFieldProps(),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                dropdownBuilder: (context, selectedItem) {
                  if (selectedItem == "__nuovo__") {
                    return const Text("Aggiungi nuovo metodo di pagamento");
                  }
                  return Text(selectedItem ?? "");
                },
                onChanged: _onMetodoPagamentoChanged,
              ),
            ),

            const SizedBox(height: 16),
            // -------------------------
            // CARD: NOTE
            // -------------------------
            _buildCard(
              title: "Note",
              child: FutureBuilder<List<String>>(
                future: DatabaseHelper.instance.getNoteUsate(),
                builder: (_, snapshot) {
                  final note = snapshot.data ?? [];

                  // Ordina alfabeticamente le note
                  note.sort(
                      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                  return Autocomplete<String>(
                    optionsBuilder: (value) {
                      if (value.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return note.where(
                        (n) => n
                            .toLowerCase()
                            .contains(value.text.toLowerCase()),
                      );
                    },
                    onSelected: (val) {
                      _notaController.text = val;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      controller.text = _notaController.text;

                      controller.addListener(() {
                        final text = controller.text;

                        // Se l’utente ha appena premuto spazio → normalizza la parola precedente
                        if (text.endsWith(" ")) {
                          final formatted =
                              normalizeSmart(text.trim()) + " ";

                          controller.value = controller.value.copyWith(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
                          );

                          _notaController.text = formatted;
                        } else {
                          // Lascia scrivere liberamente
                          _notaController.text = text;
                        }
                      });

                      focusNode.addListener(() {
                        if (!focusNode.hasFocus) {
                          final cleaned =
                              normalizeSmart(controller.text.trim());
                          controller.text = cleaned;
                          _notaController.text = cleaned;
                        }
                      });

                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Annotazioni…',
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------
            // CARD: ARTICOLI
            // -------------------------
            _buildCard(
              title: "Articoli",
              child: TextField(
                controller: _articoliController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Es. Latte, Pane, Uova…",
                ),
              ),
            ),
          ],
        ),
      ),
      // ⭐ PULSANTE DI DEBUG OCR
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.bug_report),
        onPressed: () {
          debugOCR("""
BAR CENTRALE
Caffe 1,20
Totale 1,20
""");
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // CARD BUILDER (Material 3 Light, minimal, con highlight OCR)
  // ------------------------------------------------------------
  Widget _buildCard({
    required String title,
    required Widget child,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? Colors.blue.shade300 : Colors.grey.shade300,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CAMBIO CATEGORIA
  // ------------------------------------------------------------
  void _onCategoriaChanged(String? val) async {
    FocusScope.of(context).unfocus();

    if (val == "__nuova__") {
      final nuova = await _creaNuovaCategoria();
      if (nuova != null) {
        final idMacroarea = await _scegliMacroarea();
        if (idMacroarea == null) return;

        await DatabaseHelper.instance.insertCategoria(
          tipo: _tipo,
          nome: nuova,
          idMacroarea: idMacroarea,
        );

        setState(() {
          _categoria = normalizeSmart(nuova);
          _descrizione = null;
        });
      }
      return;
    }

    // Ramo normale
    setState(() {
      _categoria = val;
      _descrizione = null;
    });
  }

  // ------------------------------------------------------------
  // CAMBIO DESCRIZIONE
  // ------------------------------------------------------------
  void _onDescrizioneChanged(String? val) async {
    FocusScope.of(context).unfocus();

    if (val == "__nuova__") {
      final nuova = await _creaNuovaDescrizione();
      if (nuova != null) {
        final norm = normalizeSmart(nuova);

        await DatabaseHelper.instance.aggiungiDescrizione(
          tipo: _tipo,
          categoria: _categoria!,
          descrizione: norm,
        );

        setState(() {
          _descrizione = norm;
        });
      }
      return;
    }

    setState(() {
      _descrizione = val;
    });
  }

  // ------------------------------------------------------------
  // CAMBIO PUNTO VENDITA
  // ------------------------------------------------------------
  void _onPuntoVenditaChanged(String? value) async {
    FocusScope.of(context).unfocus();

    if (value == "__nuovo__") {
      final nuovo = await _creaNuovoPuntoVendita();
      if (nuovo != null) {
        await DatabaseHelper.instance.insertPuntoVendita(nuovo);
        setState(() {
          _listaPuntiVendita.add(nuovo);
          _listaPuntiVendita.sort(
              (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          _puntoVenditaController.text = normalizeSmart(nuovo);
        });
      }
      return;
    }

    setState(() {
      _puntoVenditaController.text = normalizeSmart(value ?? "");
    });
  }

  // ------------------------------------------------------------
  // CAMBIO METODO PAGAMENTO
  // ------------------------------------------------------------
  void _onMetodoPagamentoChanged(String? value) async {
    FocusScope.of(context).unfocus();

    if (value == "__nuovo__") {
      final nuovo = await _creaNuovoMetodoPagamento();
      if (nuovo != null) {
        await DatabaseHelper.instance.aggiungiMetodoPagamento(nuovo);
        setState(() => _metodoPagamento = normalizeSmart(nuovo));
      }
      return;
    }

    setState(() => _metodoPagamento = normalizeSmart(value ?? ""));
  }

  // ------------------------------------------------------------
  // POPUP: NUOVA CATEGORIA
  // ------------------------------------------------------------
  Future<String?> _creaNuovaCategoria() async {
    String temp = "";
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuova categoria"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Inserisci nuova categoria",
            ),
            onChanged: (v) {
              if (v.endsWith(" ")) {
                final formatted = normalizeSmart(v.trim()) + " ";
                controller.value = controller.value.copyWith(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
                temp = formatted;
              } else {
                temp = v;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                final cleaned = temp.trim();
                if (cleaned.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context, cleaned);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // POPUP: NUOVA DESCRIZIONE
  // ------------------------------------------------------------
  Future<String?> _creaNuovaDescrizione() async {
    String temp = "";
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuova descrizione"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Inserisci nuova descrizione",
            ),
            onChanged: (v) {
              if (v.endsWith(" ")) {
                final formatted = normalizeSmart(v.trim()) + " ";
                controller.value = controller.value.copyWith(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
                temp = formatted;
              } else {
                temp = v;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                final cleaned = temp.trim();
                if (cleaned.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context, cleaned);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // POPUP: NUOVO PUNTO VENDITA
  // ------------------------------------------------------------
  Future<String?> _creaNuovoPuntoVendita() async {
    String temp = "";
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo punto vendita"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Inserisci nuovo punto vendita",
            ),
            onChanged: (v) {
              if (v.endsWith(" ")) {
                final formatted = normalizeSmart(v.trim()) + " ";
                controller.value = controller.value.copyWith(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
                temp = formatted;
              } else {
                temp = v;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                final cleaned = temp.trim();
                if (cleaned.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context, cleaned);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // POPUP: NUOVO METODO PAGAMENTO
  // ------------------------------------------------------------
  Future<String?> _creaNuovoMetodoPagamento() async {
    String temp = "";
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo metodo di pagamento"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Inserisci nuovo metodo",
            ),
            onChanged: (v) {
              if (v.endsWith(" ")) {
                final formatted = normalizeSmart(v.trim()) + " ";
                controller.value = controller.value.copyWith(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
                temp = formatted;
              } else {
                temp = v;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                final cleaned = temp.trim();
                if (cleaned.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(context, cleaned);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SALVATAGGIO
  // ------------------------------------------------------------
  void _salva() {
    final importo =
        double.tryParse(_importoController.text.replaceAll(',', '.'));

    if (_categoria == null ||
        _descrizione == null ||
        importo == null ||
        importo <= 0) {
      print("DEBUG UI: campi obbligatori mancanti");
      return;
    }

    // Normalizzazione finale
    _categoria = _categoria;
    _descrizione = normalizeSmart(_descrizione ?? "");
    _metodoPagamento = normalizeSmart(_metodoPagamento ?? "");
    _puntoVenditaController.text =
        normalizeSmart(_puntoVenditaController.text);

    print("DEBUG UI: creo Movimento");

    final movimento = Movimento(
      id: widget.movimentoDaModificare?.id,
      tipo: _tipo,
      data: _data,
      categoria: _categoria!,
      descrizione: _descrizione!,
      importo: importo,
      puntoVendita: _puntoVenditaController.text,
      metodoPagamento: _metodoPagamento ?? "",
      nota: _notaController.text,
      articoli: _articoliController.text,
      origine: OrigineDati.manuale,
      searchCategoria: normalizeSearch(_categoria!),
      searchDescrizione: normalizeSearch(_descrizione!),
      searchPuntoVendita: normalizeSearch(_puntoVenditaController.text),
      searchMetodoPagamento: normalizeSearch(_metodoPagamento ?? ""),
      dataCreazione: DateTime.now(),
      idMacroarea: null, // lo calcola insertMovimento()
    );

    print("DEBUG UI: movimento creato → Navigator.pop");

    Navigator.pop(context, movimento);
  }

  // ------------------------------------------------------------
  // FUNZIONE DI PULIZIA NOTA
  // ------------------------------------------------------------
  String? _cleanNota(String input) {
    if (input.isEmpty) return null;

    // Rimuove spazi finali
    String cleaned = input.replaceAll(RegExp(r'\s+$'), '');

    // Rimuove caratteri invisibili Unicode
    cleaned = cleaned.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Trim finale
    cleaned = cleaned.trim();

    return cleaned.isEmpty ? null : cleaned;
  }
}