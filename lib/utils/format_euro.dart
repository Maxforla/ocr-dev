import '../database_helper.dart';

String euro(double value) {
  final formatted = DatabaseHelper.instance.formatEuro(value);
  return "€ $formatted";
}

