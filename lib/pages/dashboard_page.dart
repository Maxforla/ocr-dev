import 'package:flutter/material.dart';
import '../database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totaleEntrate = 0.0;
  double totaleUscite = 0.0;

  double necessita = 0.0;
  double desideri = 0.0;
  double risparmio = 0.0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final db = DatabaseHelper.instance;

    // 1. Entrate
    final entrate = await db.getTotaleEntrateMese(year, month);

    // 2. Uscite totali
    final uscite = await db.getTotaleUsciteMese(year, month);

    // 3. Uscite per macroarea
    final perMacro = await db.getUscitePerMacroarea(year, month);

    setState(() {
      totaleEntrate = entrate;
      totaleUscite = uscite;

      necessita = perMacro["Necessità"] ?? 0.0;
      desideri = perMacro["Desideri"] ?? 0.0;
      risparmio = perMacro["Risparmio"] ?? 0.0;

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard 50‑30‑20"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ⭐ SEZIONE 1 — Entrate totali del mese
                  const Text(
                    "Entrate del mese",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _valueCard("Totale entrate", totaleEntrate),

                  const SizedBox(height: 24),

                  // ⭐ SEZIONE 2 — Massimali 50‑30‑20
                  const Text(
                    "Massimali 50‑30‑20",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _valueCard("Necessità (50%)", totaleEntrate * 0.50),
                  _valueCard("Desideri (30%)", totaleEntrate * 0.30),
                  _valueCard("Risparmio (20%)", totaleEntrate * 0.20),

                  const SizedBox(height: 24),

                  // ⭐ SEZIONE 3 — Spese reali del mese
                  const Text(
                    "Spese reali",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _valueCard("Necessità", necessita),
                  _valueCard("Desideri", desideri),
                  _valueCard("Risparmio", risparmio),
                ],
              ),
            ),
    );
  }

  // 🔧 Card con valore reale
  Widget _valueCard(String label, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "${value.toStringAsFixed(2)} €",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}