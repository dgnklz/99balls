import 'dart:async';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/sfx_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// Geri basınç: süren başlatmalar sınırlı; geç ses yerine atlama.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late SfxDispatcher dispatcher;
  late List<Completer<void>> starts;

  setUp(() {
    dispatcher = SfxDispatcher();
    starts = [];
  });

  Future<void>? request(String file, {bool important = false}) => dispatcher.dispatch<void>(
        file,
        () {
          final c = Completer<void>();
          starts.add(c);
          return c.future;
        },
        important: important,
      );

  test('a second request for the same file is skipped until the first start completes', () async {
    expect(request('hit_1'), isNotNull);
    expect(request('hit_1'), isNull);
    expect(dispatcher.takeSkipped(), 1);
    starts.single.complete();
    await _flush();
    expect(request('hit_1'), isNotNull);
  });

  test('with $kSfxMaxPendingStarts unimportant starts pending, a 4th unimportant is skipped, '
      'an important one is accepted', () {
    expect(request('hit_1'), isNotNull);
    expect(request('hit_2'), isNotNull);
    expect(request('wall'), isNotNull);
    expect(dispatcher.pending, kSfxMaxPendingStarts);
    expect(request('shoot'), isNull);
    expect(request('break', important: true), isNotNull);
  });

  test('an important sound is skipped only when its own file is busy', () {
    for (final f in ['hit_1', 'hit_2', 'wall', 'shoot']) {
      request(f);
    }
    expect(request('pickup', important: true), isNotNull);
    expect(request('pickup', important: true), isNull);
    expect(request('star', important: true), isNotNull);
  });

  test('a failing start releases its slot (no leak)', () async {
    final f = request('hit_1')!;
    unawaited(f.catchError((Object _) {}));
    starts.single.completeError(StateError('platform'));
    await _flush();
    expect(dispatcher.pending, 0);
    expect(dispatcher.pendingFor('hit_1'), 0);
    expect(request('hit_1'), isNotNull);
  });

  test('a start that throws synchronously is released and skipped', () {
    expect(dispatcher.dispatch<void>('x', () => throw StateError('sync'), important: true), isNull);
    expect(dispatcher.pending, 0);
  });

  test('a rain of 100 requests never has more than $kSfxMaxPendingStarts starts pending', () async {
    const files = ['hit_1', 'hit_2', 'hit_3', 'wall', 'shoot'];
    var maxPending = 0;
    for (var i = 0; i < 100; i++) {
      request(files[i % files.length]);
      if (dispatcher.pending > maxPending) maxPending = dispatcher.pending;
      if (i % 7 == 0 && starts.isNotEmpty) {
        final c = starts.removeAt(0);
        if (!c.isCompleted) c.complete();
        await _flush();
      }
    }
    expect(maxPending, lessThanOrEqualTo(kSfxMaxPendingStarts));
  });
}
