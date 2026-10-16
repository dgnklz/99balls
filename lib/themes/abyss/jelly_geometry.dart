import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';

/// Abyss hedefinin (denizanası) ve yıldızının geometrisi; orijin = merkez, gu.
/// Silüet çarpışma dairesinin ([kTargetRadius]) içinde kalır; çarpışma
/// yarıçapı değişmez, alan haleyle sezdirilir (testli).
abstract final class JellyGeometry {
  /// Kubbe + gövde + dalgalı etek (dolu biçim).
  static Path body() {
    const sideX = kAbyssBellRadiusX;
    const cornerTop = kAbyssHemY - kAbyssHemCornerRadius;
    const hemHalf = sideX - kAbyssHemCornerRadius;
    const waveWidth = 2 * hemHalf / kAbyssHemWaves;
    final path = Path()
      ..moveTo(-sideX, kAbyssBellCenterY)
      ..arcTo(
        Rect.fromCenter(
          center: const Offset(0, kAbyssBellCenterY),
          width: 2 * kAbyssBellRadiusX,
          height: 2 * kAbyssBellRadiusY,
        ),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(sideX, cornerTop)
      ..arcToPoint(
        const Offset(hemHalf, kAbyssHemY),
        radius: const Radius.circular(kAbyssHemCornerRadius),
      );
    // Kuadratik eğrinin en derin noktası kontrol derinliğinin yarısıdır.
    for (var i = 0; i < kAbyssHemWaves; i++) {
      final x = hemHalf - i * waveWidth;
      path.quadraticBezierTo(
        x - waveWidth / 2,
        kAbyssHemY + 2 * kAbyssHemDepth,
        x - waveWidth,
        kAbyssHemY,
      );
    }
    return path
      ..arcToPoint(
        const Offset(-sideX, cornerTop),
        radius: const Radius.circular(kAbyssHemCornerRadius),
      )
      ..close();
  }

  /// Etek altından sarkan kısa, S kıvrımlı dokunaçlar (çizgi).
  static Path tentacles() {
    const third = (kAbyssTentacleBottom - kAbyssTentacleTop) / 3;
    final path = Path();
    for (final x in kAbyssTentacleXs) {
      path
        ..moveTo(x, kAbyssTentacleTop)
        ..cubicTo(
          x + kAbyssTentacleAmp,
          kAbyssTentacleTop + third,
          x - kAbyssTentacleAmp,
          kAbyssTentacleTop + 2 * third,
          x,
          kAbyssTentacleBottom,
        );
    }
    return path;
  }

  /// Kubbedeki parlak vurgu.
  static const Rect gloss = Rect.fromLTRB(
    kAbyssGlossX - kAbyssGlossRadiusX,
    kAbyssGlossY - kAbyssGlossRadiusY,
    kAbyssGlossX + kAbyssGlossRadiusX,
    kAbyssGlossY + kAbyssGlossRadiusY,
  );

  /// HP rakamının kutusu (1–2 ve 3 hane), merkezde.
  static const Rect digitBox = Rect.fromLTRB(
    -kAbyssDigitBoxHalfW,
    -kAbyssDigitBoxHalfH,
    kAbyssDigitBoxHalfW,
    kAbyssDigitBoxHalfH,
  );
  static const Rect digitBox3 = Rect.fromLTRB(
    -kAbyssDigitBox3HalfW,
    -kAbyssDigitBox3HalfH,
    kAbyssDigitBox3HalfW,
    kAbyssDigitBox3HalfH,
  );

  /// Halenin görünür dış sınırı (yarıçap + 2σ; ötesi %2'nin altında) ve
  /// pişirilen resmin yarıçapı (yarıçap + 3σ).
  static const double haloVisibleExtent = kAbyssHaloRadius + 2 * kAbyssHaloBlur;
  static const double haloSpriteExtent = kAbyssHaloRadius + kGlowSpriteSigmas * kAbyssHaloBlur;

  /// Yuvarlak kollu deniz yıldızı: iç köşeler arasında kuadratik kollar; kol
  /// ucu ortak yıldız boyutunda ([kStarSizeRatio]).
  static Path starfish() {
    const outer = kTargetRadius * kStarSizeRatio;
    const inner = outer * kAbyssStarInnerRatio;
    const control = outer * kAbyssStarControlRatio;
    const step = 2 * math.pi / kStarPoints;
    Offset polar(double r, double a) => Offset(r * math.cos(a), r * math.sin(a));
    final path = Path();
    for (var i = 0; i < kStarPoints; i++) {
      final tip = -math.pi / 2 + i * step;
      final from = polar(inner, tip - step / 2);
      final c = polar(control, tip);
      final to = polar(inner, tip + step / 2);
      if (i == 0) path.moveTo(from.dx, from.dy);
      path.quadraticBezierTo(c.dx, c.dy, to.dx, to.dy);
    }
    return path..close();
  }
}
