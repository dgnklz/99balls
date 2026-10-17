import '../config/game_config.dart';

/// Çalmakta olan bir efekti durduran işlev (AudioPool.start'ın döndürdüğü).
typedef StopSfx = Future<void> Function();

/// Uçuşa ait efektlerin (vuruş, duvar) uçuş bitince kesilmesi.
///
/// Her istek, istendiği andaki uçuş sayacını taşır. [cut] sayacı artırır ve
/// o an çalmakta olan uçuş seslerini durdurur. Sayacı eski olan **her** başlatma
/// (uçuş sırasında istenip uçuş bittikten sonra tamamlanan) çalmaya başladığı
/// anda durdurulur; sayı sınırı yoktur. Çalan sesler süreleri
/// (+ [kSfxFlightStopMarginMs]) boyunca takip edilir, bitenler listeden düşer.
/// Yeni uçuşun sesleri etkilenmez.
///
/// Platformdan bağımsızdır (testte sahte başlatmalar ve sahte saatle sınanır).
class FlightSfxGate {
  final int Function() _nowMs;
  int _flight = 0;

  /// Çalan uçuş sesleri: (durdurma işlevi, beklenen bitiş ms).
  final List<(StopSfx, int)> _playing = [];

  /// Uçuş → başlatması henüz tamamlanmamış istek sayısı.
  final Map<int, int> _waiting = {};

  /// Uçuş → bittikten sonra tamamlanıp hemen durdurulan başlatma sayısı.
  final Map<int, int> _late = {};

  /// Bitmiş uçuş → son bekleyen başlatması da tamamlanınca çağrılacak işlev.
  final Map<int, void Function(int lateStopped)> _onSettled = {};

  /// Toplam gecikmiş durdurma (testler için).
  int lateStopped = 0;

  FlightSfxGate({int Function()? nowMs}) : _nowMs = nowMs ?? _stopwatchMs;

  static final Stopwatch _clock = Stopwatch()..start();
  static int _stopwatchMs() => _clock.elapsedMilliseconds;

  int get flight => _flight;

  /// Takipteki (hâlâ çalıyor sayılan) uçuş sesi sayısı.
  int get playing {
    _prune();
    return _playing.length;
  }

  /// Bu uçuşun tamamlanmamış başlatma sayısı.
  int get waiting => _waiting[_flight] ?? 0;

  /// [started] tamamlanınca: uçuş bitmişse ses hemen durdurulur, bitmemişse
  /// [durationMs] (+ pay) boyunca takip edilir. Uçuş sesi değilse yok sayılır.
  void track(Future<StopSfx> started, {required bool flightSound, required int durationMs}) {
    if (!flightSound) return;
    final flight = _flight;
    _waiting[flight] = (_waiting[flight] ?? 0) + 1;
    started.then((stop) {
      if (flight != _flight) {
        lateStopped++;
        _late[flight] = (_late[flight] ?? 0) + 1;
        _stop(stop);
      } else {
        _prune();
        _playing.add((stop, _nowMs() + durationMs + kSfxFlightStopMarginMs));
      }
      _settle(flight);
    }, onError: (Object _) => _settle(flight));
  }

  /// Uçuş bitti: sayaç artar, çalan uçuş sesleri durur. Durdurulan sayısını
  /// döndürür. [onSettled]: bu uçuşun bekleyen son başlatması da tamamlanınca
  /// (yoksa hemen) gecikmiş durdurma sayısıyla çağrılır.
  int cut({void Function(int lateStopped)? onSettled}) {
    final ended = _flight;
    _flight++;
    _prune();
    final count = _playing.length;
    for (final (stop, _) in _playing) {
      _stop(stop);
    }
    _playing.clear();
    if (onSettled != null) {
      if ((_waiting[ended] ?? 0) == 0) {
        onSettled(_late.remove(ended) ?? 0);
      } else {
        _onSettled[ended] = onSettled;
      }
    }
    return count;
  }

  void _settle(int flight) {
    final left = (_waiting[flight] ?? 1) - 1;
    if (left > 0) {
      _waiting[flight] = left;
      return;
    }
    _waiting.remove(flight);
    if (flight == _flight) return; // uçuş sürüyor
    final late = _late.remove(flight) ?? 0;
    _onSettled.remove(flight)?.call(late);
  }

  /// Süresi (+ pay) dolmuş sesleri takipten çıkarır: oynatıcıları havuza dönmüş
  /// olabilir, durdurulmaları başka bir sesi kesebilirdi.
  void _prune() {
    final now = _nowMs();
    _playing.removeWhere((entry) => entry.$2 <= now);
  }

  static void _stop(StopSfx stop) {
    stop().catchError((Object _) {});
  }
}
