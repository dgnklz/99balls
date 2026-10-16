import 'package:balls_99/features/game/widgets/letterbox_painter.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/placeholder/placeholder_themes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Letterbox degradesi yalnızca boyut ya da palet değişince yeniden üretilir.
void main() {
  test('shader is rebuilt only when size or palette changes', () {
    final cache = LetterboxShaderCache();
    cache.ensure(const Size(400, 800), orbitfallPalette);
    final first = cache.gradient.shader;
    cache.ensure(const Size(400, 800), orbitfallPalette);
    expect(identical(cache.gradient.shader, first), isTrue);

    cache.ensure(const Size(500, 800), orbitfallPalette);
    final second = cache.gradient.shader;
    expect(identical(second, first), isFalse);

    cache.ensure(const Size(500, 800), abyssTheme.palette);
    expect(identical(cache.gradient.shader, second), isFalse);
    // Paint rengi 8 bit kanallara yuvarlar; ARGB değeriyle karşılaştır.
    expect(cache.top.color.toARGB32(), abyssTheme.palette.hudBar.toARGB32());
    expect(cache.bottom.color.toARGB32(), abyssTheme.palette.floorBar.toARGB32());
  });
}
