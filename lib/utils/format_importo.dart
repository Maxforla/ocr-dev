String formatImportoRealtime(String input) {
  if (input.isEmpty) return "";

  // Rimuovi punti di separazione migliaia inseriti a mano
  input = input.replaceAll(".", "");

  // Solo numeri → aggiungo ,00
  if (RegExp(r'^\d+$').hasMatch(input)) {
    return "$input,00";
  }

  // Gestione con virgola
  if (input.contains(",")) {
    final parts = input.split(",");
    final intero = parts[0];
    var decimali = parts.length > 1 ? parts[1] : "";

    if (decimali.isEmpty) decimali = "00";
    if (decimali.length == 1) decimali = "${decimali}0";
    if (decimali.length > 2) decimali = decimali.substring(0, 2);

    return "$intero,$decimali";
  }

  return input;
}