import '../config/game_config.dart';

/// Geri basınç: başlatmalar platform iş parçacığında sıraya girip birikmesin.
///
/// - Bir dosyanın en çok [kSfxMaxPendingPerFile] başlatması aynı anda sürer;
///   bitmeden gelen yeni istek atlanır.
/// - Toplam süren başlatma [kSfxMaxPendingStarts] ve üstündeyken önemsiz
///   sesler (vuruş, duvar, atış) atlanır; önemli sesler yalnızca kendi
///   dosyası meşgulse atlanır.
/// - Başlatma başarıyla ya da hatayla bitince sayaç düşer.
///
/// Geç çalan ses yerine sessizlik: kuyruk hiç oluşmaz. Saate bağlı değildir;
/// platformdan bağımsızdır (testte sahte başlatmalarla sınanır).
class SfxDispatcher {
  final Map<String, int> _pendingByFile = {};
  int _pending = 0;
  int _skipped = 0;

  /// Süren (tamamlanmamış) başlatma sayısı.
  int get pending => _pending;

  int pendingFor(String file) => _pendingByFile[file] ?? 0;

  /// Son çağrıdan beri geri basınçla atlanan istek sayısı (sayaç sıfırlanır).
  int takeSkipped() {
    final skipped = _skipped;
    _skipped = 0;
    return skipped;
  }

  /// [start]'ı çağırır ve dönen Future'ı verir; geri basınç varsa çağırmaz,
  /// null döner.
  Future<T>? dispatch<T>(String file, Future<T> Function() start, {required bool important}) {
    if (pendingFor(file) >= kSfxMaxPendingPerFile ||
        (!important && _pending >= kSfxMaxPendingStarts)) {
      _skipped++;
      return null;
    }
    _pendingByFile[file] = pendingFor(file) + 1;
    _pending++;
    final Future<T> started;
    try {
      started = start();
    } catch (_) {
      _release(file);
      return null;
    }
    started.then((_) => _release(file), onError: (Object _) => _release(file));
    return started;
  }

  void _release(String file) {
    _pending--;
    final left = pendingFor(file) - 1;
    if (left > 0) {
      _pendingByFile[file] = left;
    } else {
      _pendingByFile.remove(file);
    }
  }
}
