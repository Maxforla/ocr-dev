// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/movimento.dart';
import 'nuovo_movimento_page.dart';
import 'gestione_vocabolari/gestione_vocabolari_page.dart';
import 'gestione_vocabolari/gestione_categorie_page.dart';
import 'gestione_vocabolari/gestione_metodi_pagamento_page.dart';
import 'dettaglio_movimento_page.dart';
import 'movimenti_page.dart';
import '../services/ocr_flow.dart';
import 'package:spese_app/utils/format_euro.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Movimento> _movimenti = [];

  MovimentoTipo? _filtroTipo;
  DateTime? _filtroMese;
  String? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    _loadMovimenti();
  }

  Future<void> _loadMovimenti() async {
    final list = await DatabaseHelper.instance.getMovimenti();

    // 🔥 Ordina per data del movimento (più recenti in alto)
    list.sort((a, b) => b.data.compareTo(a.data));

    setState(() {
      _movimenti
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _caricaMovimenti() async {
    final lista = await DatabaseHelper.instance.getMovimenti();

    // 🔥 Ordina per data del movimento (più recenti in alto)
    lista.sort((a, b) => b.data.compareTo(a.data));

    setState(() {
      _movimenti
        ..clear()
        ..addAll(lista);
    });
  }

  void _apriImpostazioni() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Gestione vocabolari'),
              subtitle: const Text('Categorie, descrizioni, metodi, punti vendita'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GestioneVocabolariPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Categorie Uscite'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GestioneCategoriePage(tipo: MovimentoTipo.uscita),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Categorie Entrate'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GestioneCategoriePage(tipo: MovimentoTipo.entrata),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Metodi di pagamento'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GestioneMetodiPagamentoPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Movimento> get _movimentiFiltrati {
    return _movimenti.where((m) {
      if (_filtroTipo != null && m.tipo != _filtroTipo) return false;
      if (_filtroCategoria != null && m.categoria != _filtroCategoria) return false;
      if (_filtroMese != null) {
        if (m.data.year != _filtroMese!.year ||
            m.data.month != _filtroMese!.month) return false;
      }
      return true;
    }).toList();
  }

  double get _totaleEntrate => _movimentiFiltrati
      .where((m) => m.tipo == MovimentoTipo.entrata)
      .fold(0.0, (sum, m) => sum + m.importo);

  double get _totaleUscite => _movimentiFiltrati
      .where((m) => m.tipo == MovimentoTipo.uscita)
      .fold(0.0, (sum, m) => sum + m.importo);

  double get _saldo => _totaleEntrate - _totaleUscite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilancio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _apriImpostazioni,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- MENU SUPERIORE ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _menuButton("Bilancio", Icons.account_balance, () {}),
                _menuButton("Movimenti", Icons.list, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MovimentiPage()),
                  );
                  await _caricaMovimenti();
                }),
                _menuButton("Statistiche", Icons.bar_chart, () {}),
                _menuButton("Impostazioni", Icons.settings, () {
                  _apriImpostazioni();
                }),
              ],
            ),
          ),

          // --- RIEPILOGO ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _box('Entrate', _totaleEntrate, Colors.green),
                _box('Uscite', _totaleUscite, Colors.red),
                _box('Saldo', _saldo, Colors.blue),
              ],
            ),
          ),

          const Divider(),

          // --- LISTA MOVIMENTI ---
          Expanded(
            child: ListView.builder(
              itemCount: _movimentiFiltrati.length,
              itemBuilder: (_, i) {
                final m = _movimentiFiltrati[i];
                return ListTile(
                  title: Text('${m.categoria} – ${m.descrizione}'),
                  subtitle: Text(
                    '${m.data.day.toString().padLeft(2, '0')}/'
                    '${m.data.month.toString().padLeft(2, '0')}/'
                    '${m.data.year}',
                  ),
                 trailing: Text(
                  euro(m.importo),
                  style: TextStyle(
                  fontSize: 16,   // <— aggiungi questa riga
                    color: m.tipo == MovimentoTipo.entrata ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                 ),
                ),

                  onTap: () async {
                    final risultato = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DettaglioMovimentoPage(movimento: m),
                      ),
                    );

                    if (risultato == "eliminato") {
                      await DatabaseHelper.instance.deleteMovimento(m.id!);
                      await _loadMovimenti();
                      return;
                    }

                    if (risultato is Movimento) {
                      if (risultato.id == null) {
                        await DatabaseHelper.instance.insertMovimento(risultato);
                      } else {
                        await DatabaseHelper.instance.updateMovimento(risultato);
                      }
                      await _loadMovimenti();
                    }
                  },
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
            heroTag: "btnAdd",
            child: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<Movimento>(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const NuovoMovimentoPage(),
                ),
              );

              if (result != null) {
                await DatabaseHelper.instance.insertMovimento(result);
                await _loadMovimenti();
              }
            },
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: "btnCamera",
            child: const Icon(Icons.camera_alt),
            onPressed: () async {
              final movimento = await OcrFlow.scan(context);
              if (movimento != null) {
                await _caricaMovimenti();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _box(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          euro(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _menuButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
