import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_503020_controller.dart';
import 'dashboard_503020_repository.dart';

import 'package:spese_app/utils/format_euro.dart';
import 'dashboard_503020_widget.dart';

class Dashboard503020Page extends StatelessWidget {
  const Dashboard503020Page({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Dashboard503020Controller(
        Dashboard503020RepositoryImpl(),
      )..init(),
      child: Consumer<Dashboard503020Controller>(
        builder: (context, c, _) {
          if (c.loading || c.data == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = c.data!;
          final macroaree = c.macroaree;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard 50-30-20'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ------------------------------------------------------------
                  /// RIGA 1 — SELETTORE MESI
                  /// ------------------------------------------------------------
                  MeseSelector(
                    mesi: c.mesi,
                    selezionato: c.meseSelezionato,
                    onChanged: c.cambiaMese,
                  ),

                  const SizedBox(height: 6),

                  /// ------------------------------------------------------------
                  /// RIGA 2 — ENTRATE TOTALI
                  /// ------------------------------------------------------------
                  buildTotaleBox(
                    label: "Entrate Totali",
                    value: euro(data.totaleEntrate),
                    color: Colors.green,
                    icon: Icons.trending_up,
                  ),

                  const SizedBox(height: 6),

                  /// ------------------------------------------------------------
                  /// RIGA 3 — PERCENTUALI + ICONA MODIFICA
                  /// ------------------------------------------------------------
                  PercentualiRow(
                    macroaree: macroaree,
                    onEdit: () => showEditPercentuali(context, c),
                  ),

                  const SizedBox(height: 6),

                  /// ------------------------------------------------------------
                  /// RIGA 4 — BUDGET CALCOLATO
                  /// ------------------------------------------------------------
                  BudgetRow(
                    macroaree: macroaree,
                    totaleEntrate: data.totaleEntrate,
                  ),

                  const SizedBox(height: 6),

                  /// ------------------------------------------------------------
                  /// RIGA 5 — USCITE TOTALI
                  /// ------------------------------------------------------------
                  buildTotaleBox(
                    label: "Uscite Totali",
                    value: euro(data.totaleUscite),
                    color: Colors.red,
                    icon: Icons.trending_down,
                  ),

                  const SizedBox(height: 6),

                  /// ------------------------------------------------------------
                  /// RIGA 6 — SPESE REALI
                  /// ------------------------------------------------------------
                  SpeseRow(
                    macroaree: macroaree,
                    spesePerMacroarea: data.spesePerMacroarea,
                  ),

                  const SizedBox(height: 10),

                  /// ------------------------------------------------------------
                  /// RIGA 7 — ANDAMENTO SPESE
                  /// ------------------------------------------------------------
                  Expanded(
                    child: AndamentoSpeseSection(
                      macroaree: macroaree,
                      totaleEntrate: data.totaleEntrate,
                      spesePerMacroarea: data.spesePerMacroarea,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
