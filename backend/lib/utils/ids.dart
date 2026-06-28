String newOrderNo() {
  final now = DateTime.now().toUtc();
  final stamp =
      '${now.year}${_two(now.month)}${_two(now.day)}${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  return 'MK$stamp${now.microsecondsSinceEpoch.toString().substring(10)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
