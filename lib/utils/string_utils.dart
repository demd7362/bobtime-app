int extractNumber(String str) {
  return int.parse(str.replaceAll(RegExp(r'[^0-9]'), ''));
}
