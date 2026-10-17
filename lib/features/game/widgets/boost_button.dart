import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../app/canvas_fit.dart';
import '../../../app/edge_guard.dart';
import '../../../core/config/game_config.dart';
import '../../../game_core/constants.dart';
import '../../../game_view/fast_forward.dart';
import '../../../l10n/app_localizations.dart';
import '../../../themes/game_theme.dart';

/// Boost butonunun ekran dikdörtgeni (mantıksal piksel = dp).
///
/// Sağ altta, oyun alanında, zemin çizgisinin üstünde: zemindeki atıcı topu ve
/// inen topları örtmesin diye en az top çapı + [kBoostButtonMarginDp] (ve en az
/// [kBoostButtonBottomGapDp]) yukarıda. Kenar koruma şeritlerinin ve tuval
/// kenarının en az [kBoostButtonMarginDp] içinde kalır.
Rect boostButtonRect(CanvasFit fit, EdgeGuard guard) {
  final floorY = fit.canvasRect.top + kFloorY * fit.scale;
  final bottomGap =
      math.max(kBoostButtonBottomGapDp, 2 * kBallRadius * fit.scale + kBoostButtonMarginDp);
  final right = math.min(fit.canvasRect.right, guard.allowed.right) - kBoostButtonMarginDp;
  final bottom = math.min(floorY - bottomGap, guard.allowed.bottom - kBoostButtonMarginDp);
  return Rect.fromLTRB(
    right - kBoostButtonSizeDp,
    bottom - kBoostButtonSizeDp,
    right,
    bottom,
  );
}

/// Uzun uçuşta beliren hızlanma (boost) butonu.
///
/// - Görünürlük [state]'ten gelir: belirir/kaybolur ([kBoostFadeMs] solma).
///   İlk belirişte tek seferlik ölçek nabzı (hareket azaltma açıksa yok).
/// - Basış yalnızca görünürken [onPressed]'i çağırır. Kaybolurken ve ardından
///   [kBoostSwallowExtraMs] boyunca buton hit-test'te kalır ve basışları hiçbir
///   şey yapmadan yutar: uçuş biterken basılan parmak nişana düşmez. Sonra
///   dokunuşlar tamamen geçer (IgnorePointer).
/// - Renkler temanın paletinden: kapalıyken yarı saydam koyu yüzey + ince açık
///   kenar + vurgu renginde "»"; açıkken vurgu dolgu + koyu "»".
class BoostButton extends StatefulWidget {
  final ValueListenable<BoostState> state;
  final ThemePalette palette;
  final VoidCallback onPressed;

  const BoostButton({
    super.key,
    required this.state,
    required this.palette,
    required this.onPressed,
  });

  @override
  State<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<BoostButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: kBoostPulseMs),
  );
  late BoostState _state = widget.state.value;
  late bool _hitTestable = _state != BoostState.hidden;
  Timer? _release;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onState);
  }

  @override
  void didUpdateWidget(BoostButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      oldWidget.state.removeListener(_onState);
      widget.state.addListener(_onState);
      _onState();
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    _release?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onState() {
    final next = widget.state.value;
    if (next == _state) return;
    final appeared = _state == BoostState.hidden;
    setState(() {
      _state = next;
      if (next != BoostState.hidden) {
        _release?.cancel();
        _hitTestable = true;
      }
    });
    if (next == BoostState.hidden) {
      _release?.cancel();
      _release = Timer(const Duration(milliseconds: kBoostFadeMs + kBoostSwallowExtraMs), () {
        if (mounted) setState(() => _hitTestable = false);
      });
    } else if (appeared && !MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _state != BoostState.hidden;
    final on = _state == BoostState.on;
    return IgnorePointer(
      ignoring: !_hitTestable,
      // Opak Listener: dikdörtgen içindeki her basış burada durur (solarken
      // de); oyunun tam ekran Listener'ına ulaşmaz.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: kBoostFadeMs),
          child: ExcludeSemantics(
            excluding: !visible,
            child: Semantics(
              button: true,
              toggled: on,
              label: AppLocalizations.of(context).boostLabel,
              child: GestureDetector(
                key: const Key('boostButton'),
                behavior: HitTestBehavior.opaque,
                onTap: visible ? widget.onPressed : null,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.scale(
                      scale: _pulse.isAnimating
                          ? 1 + (kBoostPulseScale - 1) * math.sin(math.pi * _pulse.value)
                          : 1,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: const Size.square(kBoostButtonVisualDp),
                      painter: _BoostPainter(widget.palette, on: on),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daire + iki chevron ("»"); yazı tipi kullanılmaz.
class _BoostPainter extends CustomPainter {
  final ThemePalette palette;
  final bool on;

  _BoostPainter(this.palette, {required this.on});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = kBoostButtonVisualDp / 2;
    canvas.drawCircle(center, radius, Paint()..color = on ? palette.hudAccent : palette.hudBar);
    if (!on) {
      canvas.drawCircle(
        center,
        radius - kBoostEdgeStrokeDp / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kBoostEdgeStrokeDp
          ..color = palette.hudEdge,
      );
    }
    // İki chevron: her biri simge kutusunun 1/3'ü genişlikte, yan yana ve ortalı.
    const width = kBoostIconSizeDp / 3;
    const half = kBoostIconSizeDp / 2;
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kBoostIconStrokeDp
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = on ? palette.onAccent : palette.hudAccent;
    final path = Path();
    for (var i = 0; i < 2; i++) {
      final left = center.dx - width + i * width;
      path
        ..moveTo(left, center.dy - half)
        ..lineTo(left + width, center.dy)
        ..lineTo(left, center.dy + half);
    }
    canvas.drawPath(path, chevron);
  }

  @override
  bool shouldRepaint(_BoostPainter old) => old.on != on || !identical(old.palette, palette);
}
