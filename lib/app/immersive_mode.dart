import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/game_config.dart';

/// Uygulamanın tam ekran denetçisi; `main` gerçek nesneyle override eder.
/// Testlerde ve önizlemede null (dinleyici bağlanmaz).
final immersiveModeProvider = Provider<ImmersiveMode?>((ref) => null);

/// Tam ekran (immersive sticky): durum ve gezinti çubukları uygulama açıkken
/// gizli kalır.
///
/// - Açılışta ve ilk karede uygulanır (main).
/// - Uygulama öne gelince (`resumed`: arka plandan, ekran kilidinden, bildirim
///   panelinden dönüş) hemen uygulanır, ardından [kImmersiveResumeBurstMs]
///   anlarında post-frame yeniden uygulanır. Uygulama yeniden ön plandan
///   çıkarsa (`resumed` dışı her durum) bu zamanlayıcılar iptal edilir.
/// - Sistem çubukları görünür olursa (kenar kaydırması vb.) yeniden gizlenir:
///   dönüş penceresi ([kImmersiveResumeWindowMs]) içinde
///   [kImmersiveResumeReapplyMs], dışında [kImmersiveReapplyMs] sonra. Art arda
///   gelen olaylar tek zamanlayıcıda birleşir (debounce); çubuklar zaten
///   gizliyse çağrı yapılmaz; kendi çağrımızın hemen ardından gelen olaylar yok
///   sayılır.
/// - Çubuklar görünür olunca dinleyiciler haber alır (aktif nişan iptali).
/// - Android'de ayrıca MainActivity.onResume ve onWindowFocusChanged gizler.
class ImmersiveMode with WidgetsBindingObserver {
  static const SystemUiMode mode = SystemUiMode.immersiveSticky;

  final Future<void> Function() _setMode;
  final int Function() _nowMs;
  final void Function(VoidCallback) _schedulePostFrame;

  /// Görünür olan çubukların yeniden gizlenmesi için bekleme (dönüş penceresi
  /// dışında).
  final Duration reapplyDelay;

  /// Dönüş penceresi içindeki yeniden gizleme beklemesi.
  final Duration resumeReapplyDelay;

  Timer? _timer;
  final List<Timer> _burst = [];
  final List<VoidCallback> _barsShownListeners = [];
  int _ignoreUntilMs = 0;
  int _resumeUntilMs = -1;
  bool _attached = false;

  ImmersiveMode({
    Future<void> Function()? setMode,
    int Function()? nowMs,
    void Function(VoidCallback)? schedulePostFrame,
    this.reapplyDelay = const Duration(milliseconds: kImmersiveReapplyMs),
    this.resumeReapplyDelay = const Duration(milliseconds: kImmersiveResumeReapplyMs),
  })  : _setMode = setMode ?? _defaultSetMode,
        _nowMs = nowMs ?? _stopwatchMs,
        _schedulePostFrame = schedulePostFrame ?? _defaultPostFrame;

  static Future<void> _defaultSetMode() => SystemChrome.setEnabledSystemUIMode(mode);

  static void _defaultPostFrame(VoidCallback callback) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => callback());
    binding.ensureVisualUpdate();
  }

  static final Stopwatch _clock = Stopwatch()..start();
  static int _stopwatchMs() => _clock.elapsedMilliseconds;

  /// Bekleyen yeniden gizleme var mı (test ve teşhis için).
  bool get reapplyPending => _timer?.isActive ?? false;

  /// Dönüş sonrası bekleyen post-frame yeniden gizleme sayısı.
  int get resumeBurstPending => _burst.where((t) => t.isActive).length;

  /// Dönüş penceresi içinde miyiz?
  bool get inResumeWindow => _nowMs() < _resumeUntilMs;

  void addBarsShownListener(VoidCallback listener) => _barsShownListeners.add(listener);

  void removeBarsShownListener(VoidCallback listener) => _barsShownListeners.remove(listener);

  /// Çubukları gizler. Bekleyen yeniden gizlemeyi iptal eder (dönüş
  /// zamanlayıcıları sürer).
  Future<void> apply() async {
    _cancelReapply();
    _ignoreUntilMs = _nowMs() + kImmersiveOwnEventWindowMs;
    await _setMode();
  }

  /// Yaşam döngüsü ve sistem çubuğu olaylarını dinlemeye başlar.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIChangeCallback(onSystemUiChange);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setSystemUIChangeCallback(null);
    _cancelAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    } else {
      // inactive / hidden / paused / detached: dönüş zamanlayıcıları ve bekleyen
      // yeniden gizleme iptal; pencere kapanır (sonraki resumed yeniden başlatır).
      _cancelAll();
    }
  }

  void _onResumed() {
    _cancelBurst();
    _resumeUntilMs = _nowMs() + kImmersiveResumeWindowMs;
    unawaited(apply());
    for (final ms in kImmersiveResumeBurstMs) {
      _burst.add(
        Timer(Duration(milliseconds: ms), () => _schedulePostFrame(() => unawaited(apply()))),
      );
    }
  }

  /// Sistem çubuklarının görünürlüğü değişti.
  Future<void> onSystemUiChange(bool systemOverlaysAreVisible) async {
    if (systemOverlaysAreVisible) {
      // Nişan iptali zararsızdır: kendi olay penceremizde de haber ver.
      for (final listener in List.of(_barsShownListeners)) {
        listener();
      }
    }
    if (_nowMs() < _ignoreUntilMs) return; // kendi çağrımızın tetiklediği olay
    if (!systemOverlaysAreVisible) {
      // Zaten gizli: yeniden uygulama yok, bekleyeni de iptal et.
      _cancelReapply();
      return;
    }
    _timer?.cancel(); // debounce: tek zamanlayıcı
    _timer = Timer(
      inResumeWindow ? resumeReapplyDelay : reapplyDelay,
      () => unawaited(apply()),
    );
  }

  void _cancelReapply() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelBurst() {
    for (final timer in _burst) {
      timer.cancel();
    }
    _burst.clear();
  }

  void _cancelAll() {
    _cancelReapply();
    _cancelBurst();
    _resumeUntilMs = -1;
  }
}
