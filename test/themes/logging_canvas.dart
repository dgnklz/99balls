import 'dart:ui';

/// Her Canvas çağrısını kaydeden sahte Canvas (çizim çağrısı testleri için).
class LoggingCanvas implements Canvas {
  final List<Invocation> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    return null;
  }

  /// Çağrılarda geçen tüm Paint'ler.
  Iterable<Paint> get paints => calls.expand((c) => c.positionalArguments.whereType<Paint>());

  /// Adı verilen çağrının sayısı (ör. 'drawImageRect').
  int count(String name) => calls.where((c) => c.memberName == Symbol(name)).length;
}
