// lib/pages/dettaglio_movimento_page.dart

import 'package:flutter/material.dart';
import '../models/movimento.dart';
import 'nuovo_movimento_page.dart';
import 'package:spese_app/utils/database_helper.dart';
import 'package:spese_app/utils/format_euro.dart';

class DettaglioMovimentoPage extends StatefulWidget {
  final Movimento movimento;

  const DettaglioMovimentoPage({
    super.key,
    required this.movimento,
  });

  @override
  State<DettaglioMovimentoPage> createState() => _DettaglioMovimentoPageState();
}

class _DettaglioMovimentoPageState extends State<DettaglioMovimentoPage> {
  bool notaEspansa = false;

  String _formatData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final movimento = widget.movimento;
    final isEntrata = movimento.tipo == MovimentoTipo.entrata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio movimento'),
        actions: [
          // ✏️ MODIFICA
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Modifica",
            onPressed: () async {
              final risultato = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NuovoMovimentoPage(
                    movimentoDaModificare: movimento,
                  ),
                ),
              );

              if (risultato is Movimento) {
                Navigator.pop(context, risultato);
              }
            },
          ),

          // 📄 DUPLICA
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Duplica",
            onPressed: () async {
              final nuovo = Movimento(
                id: null,
                tipo: movimento.tipo,
                data: DateTime.now(),
                categoria: movimento.categoria,
                descrizione: movimento.descrizione,
                importo: movimento.importo,
                puntoVendita: movimento.puntoVendita,
                metodoPagamento: movimento.metodoPagamento,
                nota: movimento.nota,
                origine: movimento.origine,
                searchCategoria: movimento.searchCategoria,
                searchDescrizione: movimento.searchDescrizione,
                searchPuntoVendita: movimento.searchPuntoVendita,
                dataCreazione: DateTime.now(),
                idMacroarea: 0,
              );

              final risultato = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NuovoMovimentoPage(
                    movimentoDaModificare: nuovo,
                  ),
                ),
              );

              if (risultato is Movimento) {
                Navigator.pop(context, risultato);
              }
            },
          ),

          // 🗑️ ELIMINA
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Elimina",
            onPressed: () async {
              final conferma = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Conferma eliminazione"),
                  content:
                      const Text("Vuoi davvero eliminare questo movimento?"),
                  actions: [
                    TextButton(
                      child: const Text("Annulla"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text("Elimina"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (conferma == true) {
                await DatabaseHelper.instance.deleteMovimento(movimento.id!);
                Navigator.pop(context, "eliminato");
              }
            },
          ),

          // 💾 SALVA (per OCR)
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Salva",
            onPressed: () async {
              print("SALVATAGGIO OCR ESEGUITO");

              final nuovoMovimento = Movimento(
                id: null,
                tipo: movimento.tipo,
                data: movimento.data,
                categoria: movimento.categoria,
                descrizione: movimento.descrizione,
                importo: movimento.importo,
                puntoVendita: movimento.puntoVendita,
                metodoPagamento: movimento.metodoPagamento,
                nota: movimento.nota,
                origine: movimento.origine,
                searchCategoria: movimento.searchCategoria,
                searchDescrizione: movimento.searchDescrizione,
                searchPuntoVendita: movimento.searchPuntoVendita,
                dataCreazione: DateTime.now(),
                idMacroarea: 0,
              );

              await DatabaseHelper.instance.insertMovimento(nuovoMovimento);
              Navigator.pop(context, nuovoMovimento);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _animatedCard(
              index: 0,
              child: _card(
                icon: isEntrata ? Icons.arrow_upward : Icons.arrow_downward,
                title: "Tipo",
                value: isEntrata ? "Entrata" : "Uscita",
                valueColor: isEntrata ? Colors.green : Colors.red,
              ),
            ),

            _animatedCard(
              index: 1,
              child: _card(
                icon: Icons.euro,
                title: "Importo",
                value: euro(movimento.importo),
              ),
            ),

            _animatedCard(
              index: 2,
              child: _card(
                icon: Icons.folder,
                title: "Categoria",
                value: movimento.categoria ?? "",
              ),
            ),

            _animatedCard(
              index: 3,
              child: _card(
                icon: Icons.label,
                title: "Descrizione",
                value: movimento.descrizione ?? "",
              ),
            ),

            _animatedCard(
              index: 4,
              child: _card(
                icon: Icons.credit_card,
                title: "Metodo di pagamento",
                value: movimento.metodoPagamento ?? "",
              ),
            ),

            _animatedCard(
              index: 5,
              child: _card(
                icon: Icons.store,
                title: "Punto vendita",
                value: movimento.puntoVendita ?? "",
              ),
            ),

            if (movimento.nota != null && movimento.nota!.isNotEmpty)
              _animatedCard(
                index: 6,
                child: _cardNota(movimento.nota!),
              ),

            if (movimento.articoli != null &&
                movimento.articoli!.trim().isNotEmpty)
              _animatedCard(
                index: 7,
                child: _card(
                  icon: Icons.list,
                  title: "Articoli",
                  value: movimento.articoli ?? "",
                ),
              ),

            _animatedCard(
              index: 8,
              child: _card(
                icon: Icons.calendar_today,
                title: "Data",
                value: _formatData(movimento.data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardNota(String nota) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 22, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              const Text(
                "Nota",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: notaEspansa
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              nota,
              maxLines: 4,
              overflow: TextOverflow.fade,
              softWrap: true,
              style: const TextStyle(fontSize: 16),
            ),
            secondChild: Text(
              nota,
              softWrap: true,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() => notaEspansa = !notaEspansa);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  notaEspansa ? "Mostra meno" : "Mostra tutto",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  notaEspansa ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCard({
    required int index,
    required Widget child,
  }) {
    final delay = Duration(milliseconds: 80 * index);

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final start = snapshot.connectionState == ConnectionState.done;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: start ? 1 : 0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}