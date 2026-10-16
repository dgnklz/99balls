import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PRD 12 kural 2: her .arb'ın anahtar kümesi app_en.arb ile birebir aynı.
Set<String> _keys(String path) {
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('tr and en .arb files have the same keys', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .map((f) => f.path)
        .toList();
    expect(arbs.length, greaterThanOrEqualTo(2));
    final en = _keys('lib/l10n/app_en.arb');
    for (final arb in arbs) {
      expect(_keys(arb), en, reason: arb);
    }
  });
}
