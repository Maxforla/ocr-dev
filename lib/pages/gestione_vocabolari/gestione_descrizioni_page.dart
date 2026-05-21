// lib/pages/gestione_vocabolari/gestione_descrizioni_page.dart

import 'package:flutter/material.dart';

import 'package:spese_app/utils/database_helper.dart';

import '../../models/movimento.dart';

class GestioneDescrizioniPage extends StatefulWidget {
  final MovimentoTipo tipo;
  final String categoria;

  const GestioneDescrizioniPage({
    super.key,
    required this.tipo,
    required this.categoria,
  });

  @override
  State<GestioneDescrizioniPage> createState() =>
      _GestioneDescrizioniPageState();
}

class _GestioneDescrizioniPageState extends State<GestioneDescrizioniPage> {
  List<String> _descrizioni = [];

  @override
  void initState() {
    super.initState();
    _loadDescrizioni();
  }

  Future<void> _loadDescrizioni() async {
    final list = await DatabaseHelper.instance.getDescrizioni(
      tipo: widget.tipo,
      categoria: widget.categoria,
    );

    setState(() => _descrizioni = []);
    await Future.delayed(const Duration(milliseconds: 10));

    setState(() {
      _descrizioni = List.from(list);
    });
  }

  Future<void> _aggiungiDescrizione() async {
    final controller = TextEditingController();

    final nuova = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuova descrizione'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Descrizione'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (nuova == null || nuova.isEmpty) return;

    await DatabaseHelper.instance.insertDescrizione(
      tipo: widget.tipo,
      categoria: widget.categoria,
      descrizione: nuova,
    );

    _loadDescrizioni();
  }

  Future<void> _rinominaDescrizione(String descrizioneAttuale) async {
    final controller = TextEditingController(text: descrizioneAttuale);

    final nuova = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rinomina descrizione'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (nuova == null ||
        nuova.isEmpty ||
        nuova == descrizioneAttuale) return;

    await DatabaseHelper.instance.updateDescrizione(
      tipo: widget.tipo,
      categoria: widget.categoria,
      oldDescrizione: descrizioneAttuale,
      newDescrizione: nuova,
    );

    _loadDescrizioni();
  }

  void _confermaEliminazioneDescrizione(String descrizione) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminare descrizione?"),
        content: Text("Vuoi davvero eliminare '$descrizione'?"),
        actions: [
          TextButton(
            child: const Text("Annulla"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Elimina",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteDescrizione(
                tipo: widget.tipo,
                categoria: widget.categoria,
                descrizione: descrizione,
              );
              Navigator.pop(context);
              _loadDescrizioni();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Descrizioni — ${widget.categoria}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiDescrizione,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _descrizioni.length,
        itemBuilder: (_, i) {
          final descrizione = _descrizioni[i];

          return ListTile(
            title: Text(descrizione),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confermaEliminazioneDescrizione(descrizione),
            ),
            onTap: () => _rinominaDescrizione(descrizione),
          );
        },
      ),
    );
  }
}