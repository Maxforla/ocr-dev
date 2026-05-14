// lib/pages/gestione_vocabolari/gestione_metodi_pagamento_page.dart

import 'package:flutter/material.dart';

import '../../database_helper.dart';

class GestioneMetodiPagamentoPage extends StatefulWidget {
  const GestioneMetodiPagamentoPage({super.key});

  @override
  State<GestioneMetodiPagamentoPage> createState() =>
      _GestioneMetodiPagamentoPageState();
}

class _GestioneMetodiPagamentoPageState
    extends State<GestioneMetodiPagamentoPage> {
  List<String> _metodi = [];

  @override
  void initState() {
    super.initState();
    _loadMetodi();
  }

  Future<void> _loadMetodi() async {
    final list = await DatabaseHelper.instance.getMetodiPagamento();

    setState(() => _metodi = []);
    await Future.delayed(const Duration(milliseconds: 10));

    setState(() {
      _metodi = List.from(list);
    });
  }

  Future<void> _aggiungiMetodo() async {
    final controller = TextEditingController();

    final nuovoNome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuovo metodo di pagamento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome metodo'),
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

    await DatabaseHelper.instance.insertMetodoPagamento(nuovoNome);
    _loadMetodi();
  }

  Future<void> _rinominaMetodo(String nomeAttuale) async {
    final controller = TextEditingController(text: nomeAttuale);

    final nuovoNome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rinomina metodo'),
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

    await DatabaseHelper.instance.updateMetodoPagamento(
      oldNome: nomeAttuale,
      newNome: nuovoNome,
    );

    _loadMetodi();
  }

  void _confermaEliminazioneMetodo(String nomeMetodo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminare metodo di pagamento?"),
        content: Text("Vuoi davvero eliminare '$nomeMetodo'?"),
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
              await DatabaseHelper.instance.deleteMetodoPagamento(nomeMetodo);
              Navigator.pop(context);
              _loadMetodi();
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
        title: const Text('Metodi di pagamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiMetodo,
          ),
        ],
      ),
      body: ListView.builder(
        key: ValueKey(_metodi.length),
        itemCount: _metodi.length,
        itemBuilder: (_, i) {
          final metodo = _metodi[i];

          return ListTile(
            title: Text(metodo),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confermaEliminazioneMetodo(metodo),
            ),
            onLongPress: () => _rinominaMetodo(metodo),
          );
        },
      ),
    );
  }
}