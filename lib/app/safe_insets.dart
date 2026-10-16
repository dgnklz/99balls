import 'dart:math' show max;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// Tam ekranda oyun tuvalinin bırakacağı güvenli alan payı (PRD 3.1).
///
/// Çubuklar gizli olduğu için yalnızca çentik/güvenli alan payı uygulanır:
/// - Android: çentik `displayFeatures` (cutout) sınırlarından hesaplanır; böylece
///   kenar kaydırmasıyla geçici görünen çubuklar yerleşimi zıplatmaz. Cihaz çentik
///   bildirmiyorsa `viewPadding`'e düşülür (çubuklar gizliyken yalnızca çentiktir).
/// - iOS: `viewPadding` (çentik ve ana ekran göstergesi güvenli alanı).
EdgeInsets gameSafeInsets(MediaQueryData data, TargetPlatform platform) {
  if (platform == TargetPlatform.iOS) return data.viewPadding;

  final size = data.size;
  var left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
  var anyCutout = false;
  for (final feature in data.displayFeatures) {
    if (feature.type != DisplayFeatureType.cutout) continue;
    anyCutout = true;
    final b = feature.bounds;
    if (b.top <= 0) {
      top = max(top, b.bottom);
    } else if (b.bottom >= size.height) {
      bottom = max(bottom, size.height - b.top);
    } else if (b.left <= 0) {
      left = max(left, b.right);
    } else if (b.right >= size.width) {
      right = max(right, size.width - b.left);
    }
  }
  return anyCutout ? EdgeInsets.fromLTRB(left, top, right, bottom) : data.viewPadding;
}
