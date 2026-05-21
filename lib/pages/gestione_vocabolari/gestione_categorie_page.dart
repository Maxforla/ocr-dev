// lib/pages/gestione_vocabolari/gestione_categorie_page.dart

import 'package:flutter/material.dart';

import 'package:spese_app/utils/database_helper.dart';

import '../../models/movimento.dart';
import 'gestione_descrizioni_page.dart';

class GestioneCategoriePage extends StatefulWidget {
  final MovimentoTipo tipo;

  const GestioneCategoriePage({super.key, required this.tipo});

  @override
  State<GestioneCategoriePage> createState() => _GestioneCategoriePageState();
}

class _GestioneCategoriePageState extends State<GestioneCategoriePage> {
  List<String> _categorie = [];

  @override
  void initState() {
    super.initState();
    _loadCategorie();
  }

  Future<void> _loadCategorie() async {
    final list = await DatabaseHelper.instance.getCategorie(tipo: widget.tipo);

    setState(() => _categorie = []);
    await Future.delayed(const Duration(milliseconds: 10));

    setState(() {
      _categorie = List.from(list);
    });
  }

 Future<void> _aggiungiCategoria() async {
  final controller = TextEditingController();

  final nuovoNome = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Nuova categoria'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nome categoria'),
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

  if (nuovoNome == null || nuovoNome.isEmpty) return;

 await DatabaseHelper.instance.insertCategoria(
  tipo: widget.tipo,
  nome: nuovoNome,
  idMacroarea: 1, // Necessità (temporaneo)
);

  _loadCategorie();
}


  Future<void> _rinominaCategoria(String nomeAttuale) async {
    final controller = TextEditingController(text: nomeAttuale);

    final nuovoNome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rinomina categoria'),
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

    if (nuovoNome == null ||
        nuovoNome.isEmpty ||
        nuovoNome == nomeAttuale) return;

    await DatabaseHelper.instance.updateCategoria(
      tipo: widget.tipo,
      oldNome: nomeAttuale,
      newNome: nuovoNome,
    );

    _loadCategorie();
  }

  void _confermaEliminazioneCategoria(String nomeCategoria) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminare categoria?"),
        content: Text("Vuoi davvero eliminare '$nomeCategoria'?"),
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
              await DatabaseHelper.instance.deleteCategoria(
                nomeCategoria,
                widget.tipo.name,
              );
              Navigator.pop(context);
              _loadCategorie();
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
        title: Text(
          widget.tipo == MovimentoTipo.uscita
              ? 'Categorie Uscite'
              : 'Categorie Entrate',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiCategoria,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _categorie.length,
        itemBuilder: (_, i) {
          final categoria = _categorie[i];

          return ListTile(
            title: Text(categoria),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confermaEliminazioneCategoria(categoria),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GestioneDescrizioniPage(
                    tipo: widget.tipo,
                    categoria: categoria,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}