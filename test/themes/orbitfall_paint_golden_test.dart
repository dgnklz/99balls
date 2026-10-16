import 'dart:io';
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Orbitfall çiziminin birebir korunduğunu denetler: aynı senaryodaki tüm
/// Canvas çağrıları (ad + argümanlar, Paint ayrıntılarıyla) golden dosyayla
/// karşılaştırılır. Ortak çizici sınıfına taşımadan önce üretildi.
///
/// Yeniden üretmek için: UPDATE_GOLDEN=1 flutter test test/themes/orbitfall_paint_golden_test.dart
const String _golden = 'test/themes/golden/orbitfall_paint_calls.txt';

/// Her çağrıyı metin olarak kaydeden sahte Canvas.
class _LoggingCanvas implements Canvas {
  final List<String> log = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    final named = invocation.namedArguments.entries.map((e) => '${e.key}=${e.value}');
    log.add('$name(${[...invocation.positionalArguments.map(_describe), ...named].join(', ')})');
    return null;
  }

  static String _describe(Object? arg) => switch (arg) {
        Paint p => 'Paint(color=${p.color.toARGB32().toRadixString(16)}, '
            'style=${p.style}, width=${p.strokeWidth}, cap=${p.strokeCap}, '
            'mask=${p.maskFilter}, shader=${p.shader != null})',
        _ => '$arg',
      };
}

List<String> _scenario() {
  final renderer = orbitfallTheme.createRenderer(orbitfallTheme);
  final canvas = _LoggingCanvas();
  for (var i = 0; i < 5; i++) {
    renderer.update(1 / 60);
  }
  renderer
    ..paintBackground(canvas)
    ..paintTarget(canvas, 100, 200, 7)
    ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
    ..paintTarget(canvas, 100, 200, 3, fill: orbitfallPalette.danger)
    ..paintTargetDisc(canvas, orbitfallPalette.danger, 0.5)
    ..paintRing(canvas, 50, 50)
    ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
    ..paintStar(canvas, 60, 60)
    ..paintStar(canvas, 60, 60, scale: 1.3, opacity: 0.3)
    ..paintBall(canvas, 208, kLaunchY)
    ..paintHud(canvas,
        score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120)
    ..paintHud(canvas,
        score: 42, counter: 7, dangerGlow: 0, sweep: -1, scoreScale: 1, floorAccentX: kLaunchStartX)
    ..paintFloatText(canvas, '+3', 100, 100, 0.5)
    ..paintFloatText(canvas, '+3', 100, 100, 1)
    ..dispose();
  return canvas.log;
}

void main() {
  test('Orbitfall paint calls match the golden log', () {
    final log = _scenario();
    expect(log, isNotEmpty);
    final file = File(_golden);
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync('${log.join('\n')}\n');
    }
    expect(log.join('\n'), file.readAsStringSync().trimRight());
  });
}
