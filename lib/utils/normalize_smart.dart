String normalizeSmart(String input) {
  if (input.trim().isEmpty) return "";

  final lowerWords = {
    "di", "a", "da", "in", "con", "su", "per", "tra", "fra",
    "al", "del", "della", "dello", "dei", "degli", "delle"
  };

  final acronyms = {
    "spa", "srl", "snc", "sas", "cgil", "cisl", "uil", "aci", "asl"
  };

  final words = input.toLowerCase().split(RegExp(r"\s+"));

  final result = words.map((w) {
    if (acronyms.contains(w)) {
      return w.toUpperCase();
    }

    if (lowerWords.contains(w)) {
      return w;
    }

    return w[0].toUpperCase() + w.substring(1);
  }).join(" ");

  return result;
}
