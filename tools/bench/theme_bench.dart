// Tema çizim yükü ölçümü (profil modu, gerçek cihaz). Ayrıntı: tools/bench/README.md
//
//   flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart
//   flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart --no-enable-impeller  (Skia)
//   flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart --dart-define=BENCH_THEME=abyss
//     (yalnızca bir tema; verilmezse hepsi)
//
// Uygulamaya gömülmez (lib/ dışında); yalnızca tema çizicilerini oyunla aynı
// çağrılarla kullanır.
import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/render_batches.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const int _warmupSec = 2;
const int _measureSec = 5;
const double _frameBudgetMs = 16;

/// Tahtalar: W en kötü (56 hedef, 6 halka, 2 yıldız, 99 top, 64 kıvılcım, HUD),
/// R gerçekçi (28 hedef, 4 halka, 1 yıldız, 99 top, 64 kıvılcım, HUD).
/// Bileşen aşamaları en kötü tahtadan tek parça çizer: b zemin, t hedef,
/// r halka + yıldız, o top, k kıvılcım, h HUD. '' boş kare (düzeneğin kendi payı).
const List<String> _allThemes = ['orbitfall', 'candyburst', 'pixeldrop', 'abyss', 'inkpaper'];
const List<String> _parts = ['W', 'R', 'b', 't', 'o', 'r', 'k', 'h'];

/// `--dart-define=BENCH_THEME=<id>` ile yalnızca o tema ölçülür; boşsa hepsi.
const String _onlyTheme = String.fromEnvironment('BENCH_THEME');
final List<String> _themes = _onlyTheme.isEmpty ? _allThemes : [_onlyTheme];

final List<(String, String)> _phases = [
  (_themes.first, ''),
  for (final theme in _themes)
    for (final part in _parts) (theme, part),
];

void main() => runApp(const _Bench());

class _Bench extends StatefulWidget {
  const _Bench();

  @override
  State<_Bench> createState() => _BenchState();
}

class _BenchState extends State<_Bench> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  final List<FrameTiming> _timings = [];
  int _phase = 0;
  late ThemeRenderer _renderer = _rendererFor(0);
  Duration _last = Duration.zero;
  double _phaseStart = 0;

  String get _part => _phases[_phase].$2;

  static ThemeRenderer _rendererFor(int phase) {
    final theme = ThemeRegistry.byId(_phases[phase].$1)!;
    return theme.createRenderer(theme);
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _ticker.start();
  }

  void _onTimings(List<FrameTiming> list) {
    final t = _time.value - _phaseStart;
    if (t >= _warmupSec && t < _warmupSec + _measureSec) _timings.addAll(list);
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 0.0 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    _renderer.update(dt);
    _time.value += dt;
    if (_time.value - _phaseStart < _warmupSec + _measureSec) return;
    _report();
    _timings.clear();
    if (_phase + 1 >= _phases.length) {
      _ticker.stop();
      debugPrint('BENCH DONE');
      return;
    }
    _renderer.dispose();
    _phase++;
    _renderer = _rendererFor(_phase);
    _phaseStart = _time.value;
  }

  void _report() {
    List<double> ms(Duration Function(FrameTiming) of) =>
        _timings.map((t) => of(t).inMicroseconds / 1000).toList()..sort();
    String stats(List<double> v) {
      if (v.isEmpty) return '-';
      double q(double p) => v[math.min(v.length - 1, (p * v.length).floor())];
      final avg = v.reduce((a, b) => a + b) / v.length;
      final over = v.where((x) => x > _frameBudgetMs).length;
      return 'ort ${avg.toStringAsFixed(2)} p95 ${q(0.95).toStringAsFixed(2)} '
          'p99 ${q(0.99).toStringAsFixed(2)} max ${v.last.toStringAsFixed(2)} ms, '
          '>${_frameBudgetMs.round()}ms: $over';
    }

    final (id, part) = _phases[_phase];
    debugPrint('BENCH $id/${part.isEmpty ? '-' : part} kare=${_timings.length} '
        'UI[${stats(ms((t) => t.buildDuration))}] '
        'RASTER[${stats(ms((t) => t.rasterDuration))}]');
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _ticker.dispose();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF000000),
        child: CustomPaint(painter: _BoardPainter(this), size: Size.infinite),
      );
}

class _BoardPainter extends CustomPainter {
  final _BenchState bench;

  // Oyunla aynı toplu arayüz (BoardComponent, BallsComponent, ParticleEffectsComponent).
  static final TargetBatch _targets = TargetBatch();
  static final BallBatch _balls = BallBatch();
  static final SparkBatch _sparks = SparkBatch();

  _BoardPainter(this.bench) : super(repaint: bench._time);

  static double _columnX(int col) => kVirtualW / kCols * (col + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final fit = CanvasFit.compute(size, EdgeInsets.zero);
    final r = bench._renderer;
    final t = bench._time.value;
    final part = bench._part;
    final worst = part == 'W';
    final realistic = part == 'R';
    final full = worst || realistic;
    bool has(String p) => full || part == p;
    final dpr = PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
    r.setPixelRatio(fit.scale * dpr); // BallGame.onGameResize ile aynı
    canvas
      ..save()
      ..translate(fit.canvasRect.left, fit.canvasRect.top)
      ..scale(fit.scale);
    if (has('b')) r.paintBackground(canvas);
    if (has('r')) {
      final rings = realistic ? 4 : 6;
      for (var k = 0; k < rings; k++) {
        r.paintRing(canvas, 40 + k * 66.0, kRow0CenterY + 4.5 * kPitch);
      }
      r.paintStar(canvas, 120, kRow0CenterY + 0.5 * kPitch);
      if (!realistic) r.paintStar(canvas, 300, kRow0CenterY + 2.5 * kPitch);
    }
    if (has('t')) {
      final rows = realistic ? kPlayableRows ~/ 2 : kPlayableRows;
      _targets.clear();
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < kCols; col++) {
          final i = row * kCols + col;
          final pulse = (i + (t * 10).floor()) % 9 == 0;
          _targets.add(_columnX(col), kRow0CenterY + row * kPitch, 1 + (i * 37) % 198,
              tscale: pulse ? kHitPulseScale : 1);
        }
      }
      r.paintTargets(canvas, _targets);
    }
    if (has('o')) {
      _balls.clear();
      for (var b = 0; b < kMaxBalls; b++) {
        final a = t * 0.9 + b * 0.21;
        _balls.add(208 + 180 * math.sin(a), 330 + 280 * math.cos(a * 1.3));
      }
      r.paintBalls(canvas, _balls);
    }
    if (has('k')) {
      _sparks.clear();
      for (var p = 0; p < kParticlePool; p++) {
        final a = p * 0.37 + t;
        _sparks.add(208 + 150 * math.cos(a), 300 + 150 * math.sin(a), 80 * math.cos(a),
            80 * math.sin(a), kSparkSize, 0xFFFFFFFF);
      }
      r.paintSparks(canvas, _sparks);
    }
    if (has('h')) {
      r.paintHud(canvas,
          score: 123, counter: 99, dangerGlow: 0, sweep: -1, scoreScale: 1, floorAccentX: 208);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}
