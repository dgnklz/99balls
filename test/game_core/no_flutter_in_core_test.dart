import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// game_core saf Dart olmalı (PRD Bölüm 2.2, 2.3, 14.1).
void main() {
  final forbidden = <String, RegExp>{
    'package:flutter': RegExp(r'package:flutter'),
    'dart:ui': RegExp(r'dart:ui'),
    'trigonometry': RegExp(r'\b(sin|cos|tan|asin|acos|atan|atan2)\s*\('),
    'DateTime.now': RegExp(r'DateTime\s*\.\s*now'),
    'Random': RegExp(r'\bRandom\b'),
    'package import outside game_core': RegExp(
      r'''(import|export)\s+['"]package:(?!balls_99/game_core/)''',
    ),
  };

  test('game_core contains no forbidden imports or APIs', () {
    final dir = Directory('lib/game_core');
    expect(dir.existsSync(), isTrue, reason: 'lib/game_core not found');

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty, reason: 'no Dart files scanned');

    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in forbidden.entries) {
          if (entry.value.hasMatch(lines[i])) {
            violations.add('${file.path}:${i + 1} [${entry.key}] ${lines[i].trim()}');
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
