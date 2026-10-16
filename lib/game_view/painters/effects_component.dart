import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../effects/anim_pools.dart';
import '../game_view.dart';

/// Yok olma animasyonları (PRD 4.5.1 katman 4, 7.2.1): sayılı topların
/// üstünde, atılan topların altında. Madeni para gibi dönüp süzülür.
class BreakEffectsComponent extends Component with HasGameReference<BallGame> {
  @override
  void render(Canvas canvas) {
    final breaks = game.effects.breaks;
    final renderer = game.renderer;
    for (var i = 0; i < breaks.capacity; i++) {
      if (!breaks.isAlive(i)) continue;
      final u = breaks.progress(i);
      final t = breaks.age[i];
      canvas
        ..save()
        ..translate(
          breaks.x[i] + BreakPool.offsetX(t, breaks.dir[i]),
          breaks.y[i] + BreakPool.offsetY(t),
        )
        ..rotate(BreakPool.rotation(u))
        ..scale(BreakPool.scaleX(u), BreakPool.scaleY(u));
      renderer.paintTargetDisc(canvas, Color(breaks.color[i]), BreakPool.opacity(u));
      canvas.restore();
    }
  }
}

/// Kıvılcımlar, halka/yıldız pop'ları, şok halkaları ve "+3" yazıları
/// (PRD 4.5.1 katman 7): nişan çizgisinin üstünde, HUD'un altında.
class ParticleEffectsComponent extends Component with HasGameReference<BallGame> {
  final Paint _shock = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kShockStroke;

  @override
  void render(Canvas canvas) {
    final effects = game.effects;
    final renderer = game.renderer;

    final pops = effects.pops;
    for (var i = 0; i < pops.capacity; i++) {
      if (!pops.isAlive(i)) continue;
      final u = pops.progress(i);
      final opacity = 1 - u;
      switch (pops.kindOf(i)) {
        case PopKind.ring:
          renderer.paintRing(canvas, pops.x[i], pops.y[i],
              scale: 1 + (kPopScale - 1) * u, opacity: opacity);
        case PopKind.star:
          renderer.paintStar(canvas, pops.x[i], pops.y[i],
              scale: 1 + (kPopScale - 1) * u, opacity: opacity);
        case PopKind.shock:
          _shock.color = game.theme.palette.danger.withValues(alpha: opacity);
          canvas.drawCircle(
            Offset(pops.x[i], pops.y[i]),
            kTargetRadius * (1 + (kShockScale - 1) * u),
            _shock,
          );
      }
    }

    final sparks = effects.sparks;
    for (var i = 0; i < sparks.capacity; i++) {
      if (!sparks.isAlive(i)) continue;
      final fade = 1 - sparks.age[i] / sparks.life[i];
      renderer.paintSpark(canvas, sparks.x[i], sparks.y[i], sparks.vx[i], sparks.vy[i],
          sparks.size[i], Color(sparks.color[i]).withValues(alpha: fade));
    }

    final texts = effects.texts;
    for (var i = 0; i < texts.capacity; i++) {
      if (!texts.isAlive(i)) continue;
      final label = game.starBonusLabel(texts.value[i]);
      if (label == null) continue;
      final u = texts.progress(i);
      renderer.paintFloatText(
        canvas,
        label,
        texts.x[i],
        texts.y[i] - kFloatTextRise * u,
        1 - u,
      );
    }
  }
}
