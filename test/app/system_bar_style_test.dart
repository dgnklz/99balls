import 'dart:ui';

import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/app/system_bar_style.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sistem çubuğu simgeleri köşenin gerçek rengine göre seçilir.
void main() {
  // 20:9 telefon: üst/alt letterbox (köşe = HUD/zemin çubuğu).
  final tall = CanvasFit.compute(const Size(360, 800), EdgeInsets.zero);
  // Geniş ekran: yan letterbox (köşe = arka plan degradesi).
  final wide = CanvasFit.compute(const Size(800, 1000), EdgeInsets.zero);

  test('layouts', () {
    expect(tall.horizontalPadding, lessThan(1));
    expect(tall.verticalPadding, greaterThan(1));
    expect(wide.horizontalPadding, greaterThan(1));
    expect(tall.canvasRect.width, closeTo(360, 1e-9));
  });

  test('dark themes: light icons in every layout (Android default)', () {
    for (final id in ['orbitfall', 'candyburst', 'pixeldrop', 'abyss']) {
      final palette = ThemeRegistry.byId(id)!.palette;
      for (final fit in [tall, wide]) {
        final style = systemBarStyle(palette, fit);
        expect(style.statusBarIconBrightness, Brightness.light, reason: id);
        expect(style.systemNavigationBarIconBrightness, Brightness.light, reason: id);
        expect(style.statusBarBrightness, Brightness.dark, reason: id);
        expect(style.statusBarColor, isNull, reason: 'only icons are set');
        expect(style.systemNavigationBarColor, isNull);
      }
    }
  });

  test('light backdrop → dark icons; dark backdrop → light icons', () {
    expect(prefersLightIcons(const Color(0xFFF1E8D6)), isFalse);
    expect(prefersLightIcons(const Color(0xFF5E5850)), isTrue);
    expect(prefersLightIcons(const Color(0xFF000000)), isTrue);
    expect(prefersLightIcons(const Color(0xFFFFFFFF)), isFalse);
  });

  test('ThemePalette fallbacks', () {
    const p = ThemePalette(
      bgTop: Color(0xFF010203),
      bgBottom: Color(0xFF000000),
      hudBar: Color(0x80000000),
      floorBar: Color(0x80000000),
      hudEdge: Color(0xFFFFFFFF),
      hudAccent: Color(0xFFFFFFFF),
      accent: Color(0xFFFFFFFF),
      guide: Color(0xFFFFFFFF),
      pickupGlow: Color(0xFFFFFFFF),
      star: Color(0xFFFFFFFF),
      bonusText: Color(0xFFFFFFFF),
      spark: Color(0xFFFFFFFF),
      textPrimary: Color(0xFFFEFEFE),
      textSecondary: Color(0xFFFFFFFF),
      danger: Color(0xFFFFFFFF),
      buttonPrimary: Color(0xFFFFFFFF),
      buttonSecondary: Color(0xFFFFFFFF),
      popupSurface: Color(0xFFFFFFFF),
      scrim: Color(0xFF000000),
      dust: Color(0xFFFFFFFF),
    );
    expect(p.onAccent, p.bgTop);
    expect(p.onBackground, p.textPrimary);
  });
}
