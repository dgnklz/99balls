import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/app/edge_guard.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kenar koruma şeritleri: dp cinsinden sabit, her ekran boyutunda aynı parmak
/// payı; gu karşılığı ölçekle değişir.
void main() {
  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(412, 915),
    Size(768, 1024),
    Size(1024, 1366),
  ];
  const insetsCases = [
    EdgeInsets.zero,
    EdgeInsets.only(top: 28), // çentik
  ];

  test('strip constants', () {
    expect(kEdgeGuardTopDp, 32);
    expect(kEdgeGuardBottomDp, 32);
    expect(kEdgeGuardSideDp, 24);
  });

  for (final size in sizes) {
    for (final insets in insetsCases) {
      test('${size.width.toInt()}x${size.height.toInt()} top inset ${insets.top}', () {
        final fit = CanvasFit.compute(size, insets);
        final guard = EdgeGuard.compute(size, insets);
        final cx = size.width / 2;
        final cy = size.height / 2;
        const eps = 1.0; // 1 dp

        // Üst: güvenli alan payı + 32 dp.
        final top = insets.top + kEdgeGuardTopDp;
        expect(guard.allowsStart(Offset(cx, top - eps)), isFalse);
        expect(guard.allowsStart(Offset(cx, top + eps)), isTrue);
        // Alt: fiziksel kenardan 32 dp.
        final bottom = size.height - kEdgeGuardBottomDp;
        expect(guard.allowsStart(Offset(cx, bottom - eps)), isTrue);
        expect(guard.allowsStart(Offset(cx, bottom + eps)), isFalse);
        // Yanlar: 24 dp.
        expect(guard.allowsStart(Offset(kEdgeGuardSideDp - eps, cy)), isFalse);
        expect(guard.allowsStart(Offset(kEdgeGuardSideDp + eps, cy)), isTrue);
        expect(guard.allowsStart(Offset(size.width - kEdgeGuardSideDp - eps, cy)), isTrue);
        expect(guard.allowsStart(Offset(size.width - kEdgeGuardSideDp + eps, cy)), isFalse);

        // dp → gu: tuvalin gu noktası CanvasFit ile ekrana çevrilir. Şeridin
        // tuval içine taşan kısmı gu'da (dp − tuval boşluğu) / ölçek'tir.
        Offset guToScreen(double gx, double gy) =>
            fit.canvasRect.topLeft + Offset(gx, gy) * fit.scale;
        final topGu = (top - fit.canvasRect.top) / fit.scale;
        if (topGu > 0) {
          expect(guard.allowsStart(guToScreen(kVirtualW / 2, topGu - eps / fit.scale)), isFalse);
          expect(guard.allowsStart(guToScreen(kVirtualW / 2, topGu + eps / fit.scale)), isTrue);
          // Ekranda şerit hep aynı dp'dir.
          expect(guToScreen(0, topGu).dy, closeTo(top, 1e-9));
        }
        final sideGu = (kEdgeGuardSideDp - fit.canvasRect.left) / fit.scale;
        if (sideGu > 0) {
          expect(guard.allowsStart(guToScreen(sideGu - eps / fit.scale, kVirtualH / 2)), isFalse);
          expect(guard.allowsStart(guToScreen(sideGu + eps / fit.scale, kVirtualH / 2)), isTrue);
          expect(guToScreen(sideGu, 0).dx, closeTo(kEdgeGuardSideDp, 1e-9));
        }
        final bottomGu = (bottom - fit.canvasRect.top) / fit.scale;
        if (bottomGu < kVirtualH) {
          expect(guard.allowsStart(guToScreen(kVirtualW / 2, bottomGu - eps / fit.scale)), isTrue);
          expect(guard.allowsStart(guToScreen(kVirtualW / 2, bottomGu + eps / fit.scale)), isFalse);
        }
        // Tuvalin ortası her zaman serbest.
        expect(guard.allowsStart(guToScreen(kVirtualW / 2, kVirtualH / 2)), isTrue);
      });
    }
  }

  test('the strip covers more gu on smaller screens (constant dp)', () {
    final small = CanvasFit.compute(const Size(320, 568), EdgeInsets.zero);
    final large = CanvasFit.compute(const Size(1024, 1366), EdgeInsets.zero);
    expect(kEdgeGuardTopDp / small.scale, greaterThan(kEdgeGuardTopDp / large.scale));
  });
}
