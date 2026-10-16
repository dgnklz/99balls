import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../../l10n/app_localizations.dart';
import '../game_theme.dart';
import '../hp_ramp.dart';
import '../orbitfall/orbitfall_renderer.dart';
import '../orbitfall/orbitfall_theme.dart';

/// YER TUTUCU temalar (M3a). Kayıtlıdırlar ve seçilebilirler, ama henüz
/// kendi çizim, efekt ve ses kimlikleri yoktur:
/// - görünüm: Orbitfall çizicisi + Orbitfall paletinin ton/doygunluk varyantı,
/// - HP durakları, efekt ayarları ve sesler: Orbitfall'ınki (ortak).
/// M3c–e'de her biri kendi teması ile değiştirilecek (Candy Burst M3b'de tamamlandı).
const String kPixelDropId = 'pixeldrop';
const String kAbyssId = 'abyss';
const String kInkPaperId = 'inkpaper';

/// Paletin arka plan, vurgu ve düğme renklerini HSL'de kaydırır; yazı, tehlike,
/// yıldız ve karartma renkleri korunur. HUD yüzeyi ve kenarı **kaydırılmaz**
/// (yarı saydam, nötre yakın koyu kalır): hiçbir ton kaydırması çubukları
/// referans oyundaki gibi dolu kırmızı/mavi çubuğa çeviremez.
ThemePalette placeholderPalette({double hueShift = 0, double saturationScale = 1}) {
  Color shift(Color c) {
    final hsl = HSLColor.fromColor(c);
    final hue = (hsl.hue + hueShift) % 360;
    final saturation = (hsl.saturation * saturationScale).clamp(0.0, 1.0);
    return hsl.withHue(hue < 0 ? hue + 360 : hue).withSaturation(saturation).toColor();
  }

  const p = orbitfallPalette;
  return ThemePalette(
    bgTop: shift(p.bgTop),
    bgBottom: shift(p.bgBottom),
    hudBar: p.hudBar,
    floorBar: p.floorBar,
    hudEdge: p.hudEdge,
    hudAccent: shift(p.hudAccent),
    accent: shift(p.accent),
    guide: shift(p.guide),
    pickupGlow: shift(p.pickupGlow),
    star: p.star,
    bonusText: p.bonusText,
    spark: shift(p.spark),
    textPrimary: p.textPrimary,
    textSecondary: shift(p.textSecondary),
    danger: p.danger,
    buttonPrimary: shift(p.buttonPrimary),
    buttonSecondary: shift(p.buttonSecondary),
    popupSurface: shift(p.popupSurface),
    scrim: p.scrim,
    dust: shift(p.dust),
  );
}

GameTheme _placeholder(
  String id,
  String Function(AppLocalizations l10n) name, {
  double hueShift = 0,
  double saturationScale = 1,
}) =>
    GameTheme(
      id: id,
      isFree: false,
      isPlaceholder: true,
      displayName: name,
      palette: placeholderPalette(hueShift: hueShift, saturationScale: saturationScale),
      hpRamp: HpRamp(orbitfallHpStops),
      effects: orbitfallEffects,
      sounds: orbitfallSounds,
      createRenderer: OrbitfallRenderer.new,
    );

final GameTheme pixelDropTheme =
    _placeholder(kPixelDropId, (l) => l.themePixelDrop, hueShift: -80);
final GameTheme abyssTheme = _placeholder(kAbyssId, (l) => l.themeAbyss, hueShift: -40);
final GameTheme inkPaperTheme =
    _placeholder(kInkPaperId, (l) => l.themeInkPaper, saturationScale: 0.25);
