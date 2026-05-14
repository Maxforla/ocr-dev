// lib/pages/gestione_vocabolari/gestione_vocabolari_page.dart

import 'package:flutter/material.dart';

import '../../models/movimento.dart';
import 'gestione_categorie_page.dart';
import 'gestione_metodi_pagamento_page.dart';
import 'gestione_punti_vendita_page.dart';

class GestioneVocabolariPage extends StatelessWidget {
  const GestioneVocabolariPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione vocabolari'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: const Text('Categorie Uscite'),
            subtitle: const Text('Gestisci le categorie delle uscite'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GestioneCategoriePage(
                    tipo: MovimentoTipo.uscita,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward),
            title: const Text('Categorie Entrate'),
            subtitle: const Text('Gestisci le categorie delle entrate'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GestioneCategoriePage(
                    tipo: MovimentoTipo.entrata,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Metodi di pagamento'),
            subtitle: const Text('Aggiungi, rinomina o elimina metodi'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GestioneMetodiPagamentoPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Punti vendita'),
            subtitle: const Text('Gestisci i punti vendita utilizzati'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GestionePuntiVenditaPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}