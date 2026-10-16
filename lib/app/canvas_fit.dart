import 'dart:math' show min;

import 'package:flutter/widgets.dart';

import '../game_core/constants.dart';

/// 416×703 gu sanal tuvalin ekrana tek ölçekle sığdırılması (PRD Bölüm 3.1).
///
/// Tuval güvenli alan içinde ortalanır; ölçek yuvarlanmaz ve üst sınırı yoktur.
/// Tüm ekranlar aynı kuralı kullanır.
@immutable
class CanvasFit {
  /// Tek ölçek katsayısı s (mantıksal piksel / gu).
  final double scale;

  /// Tuvalin ekrandaki dikdörtgeni (mantıksal piksel).
  final Rect canvasRect;

  /// Tüm ekran.
  final Size screenSize;

  const CanvasFit._(this.scale, this.canvasRect, this.screenSize);

  factory CanvasFit.compute(Size screen, EdgeInsets insets) {
    final availW = screen.width - insets.left - insets.right;
    final availH = screen.height - insets.top - insets.bottom;
    final s = min(availW / kVirtualW, availH / kVirtualH);
    final canvasW = kVirtualW * s;
    final canvasH = kVirtualH * s;
    final origin = Offset(
      insets.left + (availW - canvasW) / 2,
      insets.top + (availH - canvasH) / 2,
    );
    return CanvasFit._(s, origin & Size(canvasW, canvasH), screen);
  }

  /// Tuvalin üstündeki boşluk (HUD rengiyle doldurulur).
  Rect get topBand => Rect.fromLTRB(0, 0, screenSize.width, canvasRect.top);

  /// Tuvalin altındaki boşluk (zemin rengiyle doldurulur).
  Rect get bottomBand =>
      Rect.fromLTRB(0, canvasRect.bottom, screenSize.width, screenSize.height);

  /// Toplam dikey ve yatay dolgu (tuval dışında kalan alan).
  double get verticalPadding => screenSize.height - canvasRect.height;
  double get horizontalPadding => screenSize.width - canvasRect.width;

  /// Piksel cinsinden sürükleme farkını gu'ya çevirir (PRD 3.2).
  Offset pixelsToGu(Offset deltaPx) => deltaPx / scale;
}
