import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';

/// Ink & Paper biçimleri; orijin = nesne merkezi, gu. Rastgelelik yalnızca
/// sabit tohumlu görsel Random'dır (oyun tohumuna dokunmaz). Hedef silüeti
/// çarpışma dairesinin ([kTargetRadius]) içinde kalır (testli).
abstract final class InkGeometry {
  static const double _deg = math.pi / 180;

  /// Varyantın gövde harmoniği fazları (sabit tohum).
  static List<double> _phases(int variant) {
    final random = math.Random(kInkGeometrySeed + variant);
    return [for (var i = 0; i < kInkBodyHarmonics.length; i++) random.nextDouble() * 2 * math.pi];
  }

  static final List<List<double>> _phaseTable = List.unmodifiable([
    for (var v = 0; v < kInkTargetVariants; v++) List<double>.unmodifiable(_phases(v)),
  ]);

  /// Gövdenin [angle] (radyan) yönündeki yarıçapı.
  static double bodyRadius(int variant, double angle) {
    final phases = _phaseTable[variant];
    var wobble = 0.0;
    for (var i = 0; i < kInkBodyHarmonics.length; i++) {
      wobble += kInkBodyHarmonicWeights[i] * math.sin(kInkBodyHarmonics[i] * angle + phases[i]);
    }
    return kInkBodyRadius + kInkBodyWobble * wobble;
  }

  static Offset _polar(double r, double a) => Offset(r * math.cos(a), r * math.sin(a));

  /// Düzensiz fırça disk (dolu).
  static Path body(int variant) {
    final path = Path();
    for (var i = 0; i < kInkBodySegments; i++) {
      final a = 2 * math.pi * i / kInkBodySegments;
      final p = _polar(bodyRadius(variant, a), a);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// Fırça kalınlığı: [head] oranında en ince → en kalın (bastırma), sonra
  /// sona doğru en inceye.
  static double _brushWidth(double t, double head, double min, double max) =>
      t < head ? min + (max - min) * t / head : max - (max - min) * (t - head) / (1 - head);

  /// Başlangıcı [startDeg], yayı [sweepDeg] olan, dış kenarı [outer], kalınlığı
  /// [_brushWidth] olan dolu fırça şeridi.
  static Path _brushBand(
    double startDeg,
    double sweepDeg,
    int segments,
    double Function(double angle) outer,
    double head,
    double minWidth,
    double maxWidth,
  ) {
    final outerPts = <Offset>[];
    final innerPts = <Offset>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final a = (startDeg + sweepDeg * t) * _deg;
      final r = outer(a);
      outerPts.add(_polar(r, a));
      innerPts.add(_polar(r - _brushWidth(t, head, minWidth, maxWidth), a));
    }
    final path = Path()..moveTo(outerPts.first.dx, outerPts.first.dy);
    for (final p in outerPts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in innerPts.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// Enso kenarı: gövdenin içinde, [kInkRimGapDeg] açıklıklı fırça halkası.
  static Path rim(int variant) => _brushBand(
        kInkRimStartDeg[variant],
        360 - kInkRimGapDeg,
        kInkBodySegments,
        (a) => bodyRadius(variant, a) - kInkRimInset,
        kInkRimHeadFraction,
        kInkRimMinStroke,
        kInkRimMaxStroke,
      );

  /// Kuru fırça dokusu: eş merkezli kısa yaylar (çizgi; gövdeye kırpılarak basılır).
  static Path streaks(int variant) {
    final random = math.Random(kInkGeometrySeed + kInkTargetVariants + variant);
    final path = Path();
    for (var i = 0; i < kInkStreakCount; i++) {
      final r = kInkStreakMinRadius +
          random.nextDouble() * (kInkStreakMaxRadius - kInkStreakMinRadius);
      final start = random.nextDouble() * 2 * math.pi;
      final sweep = (kInkStreakMinSweepDeg +
              random.nextDouble() * (kInkStreakMaxSweepDeg - kInkStreakMinSweepDeg)) *
          _deg;
      path.addArc(Rect.fromCircle(center: Offset.zero, radius: r), start, sweep);
    }
    return path;
  }

  /// Fırça halka: dış kenar [kPickupRadius]; uçları üst üste biner, içi boş.
  static Path ring() => _brushBand(
        kInkRingStartDeg,
        360 + kInkRingOverlapDeg,
        kInkRingSegments,
        (_) => kPickupRadius,
        kInkRingHeadFraction,
        kInkRingMinStroke,
        kInkRingMaxStroke,
      );

  /// Mürekkep damlası: +x yönünde uzamış oval + varyantın uydu damlacıkları.
  static Path drop(int variant) {
    const r = kInkDropRadius;
    final path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset.zero,
        width: 2 * r * kInkDropStretch,
        height: 2 * r,
      ));
    final sats = kInkDropSatellites[variant];
    for (var i = 0; i + 2 < sats.length; i += 3) {
      path.addOval(Rect.fromCircle(center: Offset(sats[i] * r, sats[i + 1] * r), radius: sats[i + 2] * r));
    }
    return path;
  }

  /// Damla sprite'ının yarıçapı (tüm uydular dahil).
  static const double dropExtent = kInkDropRadius * kInkDropExtent;

  /// HP rakamının kutusu (1–2 ve 3 hane), merkezde.
  static const Rect digitBox = Rect.fromLTRB(
    -kInkDigitBoxHalfW,
    -kInkDigitBoxHalfH,
    kInkDigitBoxHalfW,
    kInkDigitBoxHalfH,
  );
  static const Rect digitBox3 = Rect.fromLTRB(
    -kInkDigitBox3HalfW,
    -kInkDigitBox3HalfH,
    kInkDigitBox3HalfW,
    kInkDigitBox3HalfH,
  );

  /// Yayılmanın görünür dış sınırı (r + 2σ) ve pişirilen resmin yarıçapı (r + 3σ).
  static const double bleedVisibleExtent = kInkBleedRadius + 2 * kInkBleedBlur;
  static const double bleedSpriteExtent = kInkBleedRadius + kGlowSpriteSigmas * kInkBleedBlur;

  /// Leke bulutu sprite'ının yarıçapı.
  static const double washExtent = kInkWashSpread + kInkWashRadius + kGlowSpriteSigmas * kInkWashBlur;

  /// Leke bulutunun daireleri (merkez ofseti ve yarıçap; sabit tohum).
  static List<(Offset, double)> washBlobs() {
    final random = math.Random(kInkGeometrySeed + 2 * kInkTargetVariants);
    return [
      for (var i = 0; i < kInkWashBlobs; i++)
        (
          Offset((random.nextDouble() * 2 - 1) * kInkWashSpread,
              (random.nextDouble() * 2 - 1) * kInkWashSpread),
          kInkWashRadius * (kInkWashBlobMinRatio + (1 - kInkWashBlobMinRatio) * random.nextDouble()),
        ),
    ];
  }

  /// Süpürme fırça darbesi: [length] × [height], iki uçta incelir.
  static Path brushStroke(double length, double height) {
    const steps = kInkBodySegments ~/ 2;
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = -length / 2 + length * t;
      // Uçlarda sıfıra inen profil; sol uç (fırçanın başı) daha dolgun.
      final profile = math.sqrt(math.sin(math.pi * t)) * (1 - kInkSweepTailTaper * t);
      top.add(Offset(x, -height / 2 * profile));
      bottom.add(Offset(x, height / 2 * profile));
    }
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in bottom.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}
