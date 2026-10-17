import 'package:flutter/services.dart';

import '../themes/game_theme.dart';
import 'canvas_fit.dart';

/// Sistem çubuğu simgelerinin rengi (tam ekranda kenardan kaydırınca beliren
/// durum ve gezinti çubukları). Simgeler ekranın köşelerindedir; köşenin
/// gerçek rengine en okunur gelen simge rengi (beyaz ya da siyah) seçilir:
/// - yanlarda letterbox varsa köşe arka plan degradesidir (bgTop / bgBottom),
/// - yoksa köşe, zeminin üstündeki yarı saydam HUD / zemin çubuğudur.
///
/// Koyu temaların hepsinde sonuç açık simgedir (Android varsayılanıyla aynı);
/// açık zeminli temada yalnızca köşe kremse koyu simge seçilir.
SystemUiOverlayStyle systemBarStyle(ThemePalette palette, CanvasFit fit) {
  final sideBands = fit.horizontalPadding >= 1;
  final top = sideBands ? palette.bgTop : Color.alphaBlend(palette.hudBar, palette.bgTop);
  final bottom =
      sideBands ? palette.bgBottom : Color.alphaBlend(palette.floorBar, palette.bgBottom);
  final topLight = prefersLightIcons(top);
  return SystemUiOverlayStyle(
    statusBarIconBrightness: topLight ? Brightness.light : Brightness.dark,
    // iOS: simge değil, arka planın parlaklığı verilir.
    statusBarBrightness: topLight ? Brightness.dark : Brightness.light,
    systemNavigationBarIconBrightness:
        prefersLightIcons(bottom) ? Brightness.light : Brightness.dark,
  );
}

/// [backdrop] üstünde beyaz, siyahtan daha yüksek kontrast veriyor mu (WCAG).
bool prefersLightIcons(Color backdrop) {
  final l = backdrop.computeLuminance();
  return 1.05 / (l + 0.05) >= (l + 0.05) / 0.05;
}
