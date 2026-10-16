import 'package:flutter/widgets.dart';

import '../core/config/game_config.dart';

/// Kenar koruma şeritleri: ekranın sistem hareket kenarlarında başlayan
/// dokunuşlar nişan başlatmaz (bildirim panelini aşağı çekmek nişan çekme
/// yönüyle aynıdır).
///
/// Şeritler fiziksel ekran kenarından mantıksal piksel (= dp) cinsinden
/// ölçülür; böylece her ekran boyutunda aynı parmak payıdır (gu karşılığı
/// `dp / CanvasFit.scale`). Üst şerit çentik/güvenli alan payının üstüne eklenir.
/// Yalnızca BAŞLANGIÇ konumu denetlenir: ortadan başlayıp kenara sürüklenen
/// nişan etkilenmez.
@immutable
class EdgeGuard {
  /// Nişanın başlayabileceği bölge (ekran, mantıksal piksel).
  final Rect allowed;

  const EdgeGuard._(this.allowed);

  factory EdgeGuard.compute(Size screen, EdgeInsets safe) => EdgeGuard._(
        Rect.fromLTRB(
          kEdgeGuardSideDp,
          safe.top + kEdgeGuardTopDp,
          screen.width - kEdgeGuardSideDp,
          screen.height - kEdgeGuardBottomDp,
        ),
      );

  /// Bu konumda başlayan dokunuş nişan başlatabilir mi?
  bool allowsStart(Offset position) => allowed.contains(position);
}
