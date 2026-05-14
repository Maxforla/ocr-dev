// lib/main.dart

import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'vocabolari.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il DB e seed iniziali
  //await DatabaseHelper.instance.seedDatiIniziali(
   // vocabUscite: vocabUscite,
   // vocabEntrate: vocabEntrate,
  //   metodiPagamentoBase: metodiPagamentoBase,
  //);

  runApp(const MyApp());
}

/* =======================
   APP
   ======================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Spese Famiglia',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}