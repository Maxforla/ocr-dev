import 'package:flutter/material.dart';
import 'dashboard_503020_controller.dart';
import 'dashboard_503020_repository.dart';
import 'package:spese_app/utils/format_euro.dart';

/// ------------------------------------------------------------
///  SELETTORE MESI
/// ------------------------------------------------------------
class MeseSelector extends StatelessWidget {
  final List<String> mesi;
  final String selezionato;
  final ValueChanged<String> onChanged;

  const MeseSelector({
    super.key,
    required this.mesi,
    required this.selezionato,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mesi.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = mesi[index];
          final isSelected = m == selezionato;

          return ChoiceChip(
            label: Text(_labelMese(m)),
            selected: isSelected,
            onSelected: (_) => onChanged(m),
          );
        },
      ),
    );
  }

  String _labelMese(String value) {
    if (value == 'Generale') return 'Generale';

    final parts = value.split('-');
    if (parts.length != 2) return value;

    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;

    const mesiShort = [
      '',
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];

    return '${mesiShort[month]} $year';
  }
}

/// ------------------------------------------------------------
///  BOX PERCENTUALI + ICONA + BOTTONE MODIFICA
/// ------------------------------------------------------------
class PercentualiRow extends StatelessWidget {
  final List<Macroarea> macroaree;
  final VoidCallback onEdit;

  const PercentualiRow({
    super.key,
    required this.macroaree,
    required this.onEdit,
  });

  IconData _iconFor(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('necess')) return Icons.shopping_bag_outlined;
    if (n.contains('desid')) return Icons.favorite_border;
    if (n.contains('rispar')) return Icons.savings_outlined;
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: macroaree.map((m) {
              return Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconFor(m.nome), size: 20),
                        const SizedBox(height: 4),
                        Text(m.nome, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${m.percentuale.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.tune),
          tooltip: 'Modifica percentuali',
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
///  BOX BUDGET CALCOLATO
/// ------------------------------------------------------------
class BudgetRow extends StatelessWidget {
  final List<Macroarea> macroaree;
  final double totaleEntrate;

  const BudgetRow({
    super.key,
    required this.macroaree,
    required this.totaleEntrate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: macroaree.map((m) {
        final budget = totaleEntrate * (m.percentuale / 100);

        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('Budget', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    euro(budget),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ------------------------------------------------------------
///  BOX SPESE REALI
/// ------------------------------------------------------------
class SpeseRow extends StatelessWidget {
  final List<Macroarea> macroaree;
  final Map<int, double> spesePerMacroarea;

  const SpeseRow({
    super.key,
    required this.macroaree,
    required this.spesePerMacroarea,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: macroaree.map((m) {
        final spesa = spesePerMacroarea[m.id] ?? 0.0;

        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('Speso', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    euro(spesa),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ------------------------------------------------------------
///  ANDAMENTO SPESE (barre dinamiche) — VERSIONE MIGLIORATA
/// ------------------------------------------------------------
class AndamentoSpeseSection extends StatelessWidget {
  final List<Macroarea> macroaree;
  final double totaleEntrate;
  final Map<int, double> spesePerMacroarea;

  const AndamentoSpeseSection({
    super.key,
    required this.macroaree,
    required this.totaleEntrate,
    required this.spesePerMacroarea,
  });

  Color _colorFor(double ratio) {
    if (ratio <= 0.8) return Colors.green;
    if (ratio <= 1.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ------------------------------------------------------------
            /// TITOLO RIPRISTINATO
            /// ------------------------------------------------------------
            const Text(
              "Andamento Spese",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            /// ------------------------------------------------------------
            /// BARRE DINAMICHE + PERCENTUALI
            /// ------------------------------------------------------------
            ...macroaree.map((m) {
              final spesa = spesePerMacroarea[m.id] ?? 0.0;
              final budget = totaleEntrate * (m.percentuale / 100);
              final ratio = budget == 0 ? 0 : spesa / budget;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Testo sopra la barra
                    Text(
                      "${m.nome} — ${euro(spesa)} / ${euro(budget)}",
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 6),

                    /// Barra + percentuale a destra
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Stack(
    children: [
      // SFONDO GRADIENT (riempito al 100%)
      Container(
        height: 10,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _colorFor(ratio.toDouble()).withOpacity(0.4), // più chiaro
              _colorFor(ratio.toDouble()),                  // più intenso
            ],
          ),
        ),
      ),

      // MASCHERA PER MOSTRARE SOLO LA PARTE "RIEMPITA"
      FractionallySizedBox(
        widthFactor: ratio.clamp(0, 1.2).toDouble(),
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _colorFor(ratio.toDouble()).withOpacity(0.4),
                _colorFor(ratio.toDouble()),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),



                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(ratio * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _colorFor(ratio.toDouble()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
/// ------------------------------------------------------------
///  BOX ENTRATE / USCITE TOTALI — VERSIONE SUPER COMPATTA
/// ------------------------------------------------------------
Widget buildTotaleBox({
  required String label,
  required String value,
  required Color color,
  required IconData icon,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withOpacity(0.35),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      children: [
        // ICONA GRANDE E PROPORZIONATA
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),

        const SizedBox(width: 10),

        // TITOLO + IMPORTO SULLA STESSA RIGA
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label, // esempio: "Entrate Tot."
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,   // ← più piccolo per ridurre altezza
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



/// ------------------------------------------------------------
///  BOTTOM SHEET MODIFICA PERCENTUALI
/// ------------------------------------------------------------
Future<void> showEditPercentuali(
  BuildContext context,
  Dashboard503020Controller c,
) async {
  final macroaree = c.macroaree
      .map((m) => Macroarea(id: m.id, nome: m.nome, percentuale: m.percentuale))
      .toList();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          double somma = macroaree.fold(
            0,
            (prev, m) => prev + m.percentuale,
          );

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modifica percentuali',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...macroaree.map((m) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nome),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: m.percentuale,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '${m.percentuale.toStringAsFixed(0)}%',
                              onChanged: (v) {
                                setState(() {
                                  final idx = macroaree.indexWhere(
                                      (mm) => mm.id == m.id);
                                  macroaree[idx] = Macroarea(
                                    id: m.id,
                                    nome: m.nome,
                                    percentuale: v,
                                  );
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${m.percentuale.toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),

                const SizedBox(height: 8),
                Text(
                  'Totale: ${somma.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: somma == 100 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: somma == 100
                          ? () async {
                              await c.aggiornaPercentuali(macroaree);
                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Salva'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
