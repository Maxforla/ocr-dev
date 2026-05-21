// lib/pages/gestione_vocabolari/gestione_punti_vendita_page.dart

import 'package:flutter/material.dart';

import 'package:spese_app/utils/database_helper.dart';


class GestionePuntiVenditaPage extends StatefulWidget {
  const GestionePuntiVenditaPage({super.key});

  @override
  State<GestionePuntiVenditaPage> createState() =>
      _GestionePuntiVenditaPageState();
}

class _GestionePuntiVenditaPageState
    extends State<GestionePuntiVenditaPage> {
  List<String> _punti = [];

  @override
  void initState() {
    super.initState();
    _loadPunti();
  }

  Future<void> _loadPunti() async {
    final lista = await DatabaseHelper.instance.getPuntiVenditaListaCompleta();

    setState(() => _punti = []);
    await Future.delayed(const Duration(milliseconds: 10));

    setState(() {
      _punti = List.from(lista);
    });
  }

  Future<void> _aggiungiPunto() async {
    final controller = TextEditingController();

    final nuovo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuovo punto vendita'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome punto vendita'),
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

    if (nuovo == null || nuovo.isEmpty) return;

    await DatabaseHelper.instance.insertPuntoVendita(nuovo);
    _loadPunti();
  }

  Future<void> _rinominaPunto(String nomeAttuale) async {
    final controller = TextEditingController(text: nomeAttuale);

    final nuovo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rinomina punto vendita'),
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

    if (nuovo == null ||
        nuovo.isEmpty ||
        nuovo == nomeAttuale) return;

    await DatabaseHelper.instance.updatePuntoVendita(
      oldNome: nomeAttuale,
      newNome: nuovo,
    );

    _loadPunti();
  }

  void _confermaEliminazione(String nome) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminare punto vendita?"),
        content: Text("Vuoi davvero eliminare '$nome'?"),
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
              await DatabaseHelper.instance.deletePuntoVendita(nome);
              Navigator.pop(context);
              _loadPunti();
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
        title: const Text('Punti vendita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiPunto,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _punti.length,
        itemBuilder: (_, i) {
          final nome = _punti[i];

          return ListTile(
            title: Text(nome),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confermaEliminazione(nome),
            ),
            onLongPress: () => _rinominaPunto(nome),
          );
        },
      ),
    );
  }
}