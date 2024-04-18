int extractNumber(String str) {
  try {
    return int.parse(str.replaceAll(RegExp(r'[^0-9]'), ''));
  } catch (e) {
    return 0;
  }
}
