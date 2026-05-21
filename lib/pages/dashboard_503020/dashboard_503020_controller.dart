import 'package:flutter/material.dart';
import 'dashboard_503020_repository.dart';
import '../../models/movimento.dart';

class Dashboard503020Controller extends ChangeNotifier {
  final Dashboard503020Repository repo;

  Dashboard503020Controller(this.repo);

  List<String> mesi = [];
  String meseSelezionato = 'Generale';

  List<Macroarea> macroaree = [];
  DashboardData? data;

  bool loading = false;

  Future<void> init() async {
    loading = true;
    notifyListeners();

    mesi = await repo.getMesiDisponibili();
    if (!mesi.contains('Generale')) {
      mesi = ['Generale', ...mesi];
    }

    macroaree = await repo.getMacroaree();
    data = await repo.getDashboardData(mese: null);

    loading = false;
    notifyListeners();
  }

  Future<void> cambiaMese(String nuovoMese) async {
    meseSelezionato = nuovoMese;
    loading = true;
    notifyListeners();

    data = await repo.getDashboardData(
      mese: meseSelezionato == 'Generale' ? null : meseSelezionato,
    );

    loading = false;
    notifyListeners();
  }

  Future<void> aggiornaPercentuali(List<Macroarea> nuove) async {
    for (final m in nuove) {
      await repo.updatePercentualeMacroarea(m.id, m.percentuale);
    }

    macroaree = await repo.getMacroaree();
    await cambiaMese(meseSelezionato);
  }
}