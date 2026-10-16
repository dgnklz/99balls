import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/themes/pixeldrop/pixel_geometry.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_renderer.dart';
import 'package:balls_99/themes/shared/baked_sprite.dart';
import 'package:balls_99/themes/shared/base_theme_renderer.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'logging_canvas.dart';

/// M3p: bulanıklık karede yapılmaz (Impeller/OpenGLES'te çok pahalı). Rakam
/// gölgesi bulanıksız; halka ve HUD parıltısı bir kez pişirilmiş resimden.
void main() {
  for (final theme in ThemeRegistry.all) {
    test('${theme.id}: no MaskFilter in any frame-time paint call', () {
      final renderer = theme.createRenderer(theme);
      final canvas = LoggingCanvas();
      renderer
        ..update(1 / 60)
        ..paintBackground(canvas)
        ..paintTarget(canvas, 100, 200, 7)
        ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
        ..paintTargetDisc(canvas, theme.palette.danger, 0.5)
        ..paintRing(canvas, 50, 50)
        ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
        ..paintStar(canvas, 60, 60)
        ..paintBall(canvas, 208, kLaunchY)
        ..paintSpark(canvas, 80, 80, kSparkSpeed, 0, kSparkSize, const Color(0xFFFFFFFF))
        ..paintHud(canvas,
            score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120);
      expect(canvas.calls, isNotEmpty);
      for (final paint in canvas.paints) {
        expect(paint.maskFilter, isNull, reason: '${theme.id}: $paint');
      }
      renderer.dispose();
    });

    test('${theme.id}: HP and HUD digits use a crisp (unblurred) offset shadow', () {
      for (final size in [kTargetFontSize, kTargetFontSize3Digits, kHudFontSize]) {
        final shadows = BaseThemeRenderer.numberStyle(theme, size).shadows ?? const <Shadow>[];
        expect(shadows, isNotEmpty);
        for (final s in shadows) {
          expect(s.blurRadius, 0);
          expect(s.offset, const Offset(0, kNumberShadowOffset));
        }
      }
    });
  }

  group('BakedSprite', () {
    test('is rendered at pxPerGu and drawn over its bounds around the centre', () {
      const bounds = Rect.fromLTRB(-10, -5, 10, 5);
      final sprite = BakedSprite.record(bounds, 3, (c) => c.drawRect(bounds, Paint()));
      expect(sprite.image.width, 60);
      expect(sprite.image.height, 30);
      final canvas = LoggingCanvas();
      sprite.draw(canvas, 100, 50, Paint(), scale: 2);
      final call = canvas.calls.single;
      expect(call.memberName, #drawImageRect);
      expect(call.positionalArguments[2], const Rect.fromLTRB(80, 40, 120, 60));
      sprite.dispose();
    });
  });

  test('glow sprites are re-baked at the new pixel ratio', () {
    final theme = ThemeRegistry.byId('orbitfall')!;
    final renderer = theme.createRenderer(theme);
    int ringImageWidth() {
      final canvas = LoggingCanvas();
      renderer.paintRing(canvas, 50, 50);
      final call = canvas.calls.firstWhere((c) => c.memberName == #drawImageRect);
      return (call.positionalArguments[0] as Image).width;
    }

    final atDefault = ringImageWidth();
    renderer.setPixelRatio(kSpritePxPerGu * 2);
    expect(renderer.pxPerGu, kSpritePxPerGu * 2);
    expect(ringImageWidth(), closeTo(atDefault * 2, 1));
    renderer.dispose();
  });

  test('BallGame passes the device pixel ratio per gu to the renderer', () {
    final game = BallGame(seed: 1);
    final dpr = PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
    game.onGameResize(Vector2(kVirtualW * 2, kVirtualH * 2));
    expect(game.pxPerGu, closeTo(2 * dpr, 1e-9));
    expect(game.renderer.pxPerGu, closeTo(2 * dpr, 1e-9));
    game.theme = ThemeRegistry.byId('pixeldrop')!;
    expect(game.renderer.pxPerGu, closeTo(2 * dpr, 1e-9), reason: 'kept across theme change');
  });

  test('Pixel Drop ring halo: one cell just outside the ring, never overlapping it', () {
    final ring = PixelDropRenderer.ringCells.toSet();
    final halo = PixelDropRenderer.ringHaloCells;
    expect(halo, isNotEmpty);
    for (final c in halo) {
      expect(ring.contains(c), isFalse, reason: '$c');
      expect(c.center.distance, greaterThan(kPickupRadius - kPixelCell), reason: 'outer side');
      expect(c.center.distance, lessThan(kPickupRadius + kPixelCell), reason: 'one cell thick');
      // Her hale hücresi halkaya 4 yönden bitişik.
      final touches = ring.any((r) =>
          (r.center - c.center).distance < kPixelCell + 1e-9);
      expect(touches, isTrue, reason: '$c');
    }
    // Sürekli çerçeve: halkanın her dış kenar hücresinin dışa bakan komşusu halede.
    expect(PixelGeometry.area(halo), greaterThan(PixelGeometry.area(PixelDropRenderer.ringCells) * 0.4));
  });
}
