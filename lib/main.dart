// lib/main.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spese_app/utils/database_helper.dart';

import 'vocabolari.dart';
import 'pages/home_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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