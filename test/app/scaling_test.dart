import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD Bölüm 3.3 doğrulama cihazları. Tablo değerleri yuvarlanmış olduğundan
/// ölçek 3 haneye, tuval ±0.5'e, dolgu ±1'e kadar karşılaştırılır.
class _Device {
  final String name;
  final Size screen;
  final EdgeInsets insets;
  final double scale;
  final Size canvas;
  final double verticalPadding;
  final double sidePadding;

  const _Device(this.name, this.screen, this.insets, this.scale, this.canvas,
      {this.verticalPadding = 0, this.sidePadding = 0});
}

const _devices = [
  _Device('iPhone SE 2', Size(375, 667), EdgeInsets.only(top: 20), 0.901, Size(375, 634),
      verticalPadding: 13),
  _Device('Galaxy A07', Size(384, 853), EdgeInsets.only(top: 28, bottom: 24), 0.923,
      Size(384, 649),
      verticalPadding: 152),
  _Device('iPhone 15 Pro Max', Size(430, 932), EdgeInsets.only(top: 59, bottom: 34), 1.034,
      Size(430, 727),
      verticalPadding: 112),
  _Device('iPad Air 11', Size(820, 1180), EdgeInsets.only(top: 24, bottom: 20), 1.616,
      Size(672, 1136),
      sidePadding: 74),
];

void _expectCenteredInSafeArea(CanvasFit fit, Size screen, EdgeInsets insets) {
  final safe = insets.deflateRect(Offset.zero & screen);
  expect(fit.canvasRect.center.dx, closeTo(safe.center.dx, 1e-9));
  expect(fit.canvasRect.center.dy, closeTo(safe.center.dy, 1e-9));
  expect(fit.canvasRect.width / fit.canvasRect.height, closeTo(kVirtualW / kVirtualH, 1e-12));
  expect(fit.canvasRect.left, greaterThanOrEqualTo(safe.left - 1e-9));
  expect(fit.canvasRect.top, greaterThanOrEqualTo(safe.top - 1e-9));
  expect(fit.canvasRect.right, lessThanOrEqualTo(safe.right + 1e-9));
  expect(fit.canvasRect.bottom, lessThanOrEqualTo(safe.bottom + 1e-9));
}

void main() {
  for (final d in _devices) {
    test('${d.name}: scale, canvas and padding match PRD 3.3', () {
      final fit = CanvasFit.compute(d.screen, d.insets);
      expect(fit.scale, closeTo(d.scale, 0.0005));
      expect(fit.canvasRect.width, closeTo(d.canvas.width, 0.5));
      expect(fit.canvasRect.height, closeTo(d.canvas.height, 0.5));
      final safeH = d.screen.height - d.insets.vertical;
      expect(safeH - fit.canvasRect.height, closeTo(d.verticalPadding, 1));
      expect((d.screen.width - fit.canvasRect.width) / 2, closeTo(d.sidePadding, 1));
      _expectCenteredInSafeArea(fit, d.screen, d.insets);
    });
  }

  test('20:9 phone (360×800, 24/48): width-bound scale, centered', () {
    const screen = Size(360, 800);
    const insets = EdgeInsets.only(top: 24, bottom: 48);
    final fit = CanvasFit.compute(screen, insets);
    expect(fit.scale, closeTo(360 / kVirtualW, 1e-12));
    expect(fit.canvasRect.width, closeTo(360, 1e-9));
    _expectCenteredInSafeArea(fit, screen, insets);
  });

  test('scale is never rounded and has no upper limit', () {
    final fit = CanvasFit.compute(const Size(2048, 2732), EdgeInsets.zero);
    expect(fit.scale, 2732 / kVirtualH); // yüksekliğe bağlı, yuvarlanmamış
    expect(fit.scale, greaterThan(3.8));
  });

  test('bands cover the screen outside the canvas', () {
    const screen = Size(430, 932);
    final fit = CanvasFit.compute(screen, const EdgeInsets.only(top: 59, bottom: 34));
    expect(fit.topBand, Rect.fromLTRB(0, 0, 430, fit.canvasRect.top));
    expect(fit.bottomBand, Rect.fromLTRB(0, fit.canvasRect.bottom, 430, 932));
  });

  test('input: drag in pixels is divided by s (PRD 3.2)', () {
    final fit = CanvasFit.compute(const Size(375, 667), const EdgeInsets.only(top: 20));
    final gu = fit.pixelsToGu(const Offset(-45, 90));
    expect(gu.dx, closeTo(-45 / fit.scale, 1e-12));
    expect(gu.dy, closeTo(90 / fit.scale, 1e-12));
  });

  test('same relative layout on small and large phones', () {
    final se = CanvasFit.compute(const Size(375, 667), const EdgeInsets.only(top: 20));
    final max = CanvasFit.compute(
        const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34));
    // Bir gu noktası her iki cihazda tuvalin aynı oranına düşer.
    const pointGu = Offset(208, 622);
    final seRel = (pointGu * se.scale).dy / se.canvasRect.height;
    final maxRel = (pointGu * max.scale).dy / max.canvasRect.height;
    expect(seRel, closeTo(maxRel, 1e-12));
  });
}
