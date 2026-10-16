import 'package:balls_99/app/immersive_mode.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tam ekran (immersive sticky), dönüş patlaması ve yeniden gizleme kuralları.
void main() {
  group('with the real platform channel (fake)', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    List<MethodCall> modeCalls() =>
        calls.where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode').toList();

    testWidgets('apply sends immersiveSticky; resumed re-applies it (post-frame burst)',
        (tester) async {
      final immersive = ImmersiveMode();
      await immersive.apply();
      expect(modeCalls().single.arguments, 'SystemUiMode.immersiveSticky');

      immersive.attach();
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        immersive.didChangeAppLifecycleState(state);
      }
      await tester.pump();
      expect(modeCalls(), hasLength(1), reason: 'only resumed re-applies');

      immersive.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(modeCalls().length, greaterThanOrEqualTo(2), reason: 'immediately on resume');
      await tester.pump(Duration(milliseconds: kImmersiveResumeBurstMs.last));
      await tester.pump(); // son zamanlayıcının post-frame çağrısı
      expect(modeCalls(), hasLength(2 + kImmersiveResumeBurstMs.length));
      expect(modeCalls().every((c) => c.arguments == 'SystemUiMode.immersiveSticky'), isTrue);
      immersive.detach();
    });
  });

  group('timers (fake clock)', () {
    late int applied;

    // Saat, testin sahte zamanıdır: zamanlayıcılar kendi anlarında çalışır.
    ImmersiveMode make(WidgetTester tester) {
      applied = 0;
      return ImmersiveMode(
        setMode: () async => applied++,
        nowMs: () => tester.binding.clock.now().millisecondsSinceEpoch,
        schedulePostFrame: (callback) => callback(),
      );
    }

    /// Kendi çağrımızın yok sayma penceresinin dışına çıkar.
    Future<void> leaveOwnWindow(WidgetTester tester) =>
        tester.pump(const Duration(milliseconds: kImmersiveOwnEventWindowMs + 1));

    testWidgets('resumed: applied immediately, then at each burst time', (tester) async {
      final immersive = make(tester);
      immersive.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(applied, 1, reason: 'immediately');
      var elapsed = 0;
      for (var i = 0; i < kImmersiveResumeBurstMs.length; i++) {
        final at = kImmersiveResumeBurstMs[i];
        if (at > elapsed) {
          await tester.pump(Duration(milliseconds: at - elapsed - 1));
          expect(applied, 1 + i, reason: 'not before ${at}ms');
          await tester.pump(const Duration(milliseconds: 1));
        } else {
          await tester.pump(Duration.zero);
        }
        elapsed = at;
        expect(applied, 2 + i, reason: 'at ${at}ms');
      }
      expect(immersive.resumeBurstPending, 0);
      await tester.pump(const Duration(milliseconds: kImmersiveResumeWindowMs * 2));
      expect(applied, 1 + kImmersiveResumeBurstMs.length, reason: 'no further calls');
    });

    testWidgets('pause after resume cancels the burst and the pending re-hide',
        (tester) async {
      for (final state in [AppLifecycleState.paused, AppLifecycleState.inactive]) {
        final immersive = make(tester);
        immersive.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump(const Duration(milliseconds: 1));
        final before = applied; // hemen + 0 ms
        // 1000 ms patlamasının yok sayma penceresinden sonra; 2000 ms'lik hâlâ bekliyor.
        await tester.pump(
          Duration(milliseconds: kImmersiveResumeBurstMs[3] + kImmersiveOwnEventWindowMs + 100),
        );
        expect(immersive.resumeBurstPending, 1);
        await immersive.onSystemUiChange(true);
        expect(immersive.reapplyPending, isTrue);
        final mid = applied;
        expect(mid, greaterThan(before));

        immersive.didChangeAppLifecycleState(state);
        expect(immersive.resumeBurstPending, 0, reason: '$state');
        expect(immersive.reapplyPending, isFalse, reason: '$state');
        expect(immersive.inResumeWindow, isFalse, reason: '$state');
        await tester.pump(const Duration(milliseconds: kImmersiveResumeWindowMs * 2));
        expect(applied, mid, reason: 'no calls after $state');
      }
    });

    testWidgets('inside the resume window bars are re-hidden after 250 ms', (tester) async {
      final immersive = make(tester);
      immersive.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // Son patlama çağrısından ve onun yok sayma penceresinden sonra; hâlâ pencerede.
      await tester.pump(Duration(milliseconds: kImmersiveResumeBurstMs.last));
      await leaveOwnWindow(tester);
      expect(immersive.inResumeWindow, isTrue);
      final base = applied;
      await immersive.onSystemUiChange(true);
      await tester.pump(const Duration(milliseconds: kImmersiveResumeReapplyMs - 1));
      expect(applied, base);
      await tester.pump(const Duration(milliseconds: 1));
      expect(applied, base + 1);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
      expect(applied, base + 1, reason: 'single re-hide');
    });

    testWidgets('outside the resume window the 3000 ms delay is kept', (tester) async {
      final immersive = make(tester);
      immersive.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: kImmersiveResumeWindowMs));
      expect(immersive.inResumeWindow, isFalse);
      final base = applied;
      await immersive.onSystemUiChange(true);
      await tester.pump(const Duration(milliseconds: kImmersiveResumeReapplyMs));
      expect(applied, base, reason: 'edge swipe not cut short');
      await tester.pump(
        const Duration(milliseconds: kImmersiveReapplyMs - kImmersiveResumeReapplyMs - 1),
      );
      expect(applied, base);
      await tester.pump(const Duration(milliseconds: 1));
      expect(applied, base + 1);
    });

    testWidgets('bars already hidden: no call', (tester) async {
      final immersive = make(tester);
      await leaveOwnWindow(tester);
      await immersive.onSystemUiChange(false);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
      expect(applied, 0);
      expect(immersive.reapplyPending, isFalse);
    });

    testWidgets('bars visible: a single re-hide after the delay (debounced)', (tester) async {
      final immersive = make(tester);
      await leaveOwnWindow(tester);
      await immersive.onSystemUiChange(true);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs ~/ 2));
      await immersive.onSystemUiChange(true);
      await immersive.onSystemUiChange(true);
      expect(applied, 0, reason: 'not before the delay');
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs - 1));
      expect(applied, 0, reason: 'timer restarted by later events');
      await tester.pump(const Duration(milliseconds: 1));
      expect(applied, 1);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
      expect(applied, 1, reason: 'exactly one re-hide');
    });

    testWidgets('bars hidden again before the delay: pending re-hide is cancelled',
        (tester) async {
      final immersive = make(tester);
      await leaveOwnWindow(tester);
      await immersive.onSystemUiChange(true);
      await immersive.onSystemUiChange(false);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
      expect(applied, 0);
    });

    testWidgets('events caused by our own call are ignored', (tester) async {
      final immersive = make(tester);
      await immersive.apply();
      expect(applied, 1);
      await tester.pump(const Duration(milliseconds: kImmersiveOwnEventWindowMs - 1));
      await immersive.onSystemUiChange(true);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
      expect(applied, 1, reason: 'own event ignored');
      await immersive.onSystemUiChange(true);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs));
      expect(applied, 2, reason: 'later user swipe is handled');
    });

    testWidgets('bars-shown listeners fire on visible events, even our own', (tester) async {
      final immersive = make(tester);
      var shown = 0;
      void listener() => shown++;
      immersive.addBarsShownListener(listener);
      await immersive.apply();
      await immersive.onSystemUiChange(true); // kendi penceremiz içinde
      expect(shown, 1);
      await immersive.onSystemUiChange(false);
      expect(shown, 1, reason: 'hidden: no notification');
      immersive.removeBarsShownListener(listener);
      await immersive.onSystemUiChange(true);
      expect(shown, 1);
      await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs * 2));
    });

    test('delays and constants', () {
      final immersive = ImmersiveMode(setMode: () async {});
      expect(kImmersiveReapplyMs, greaterThanOrEqualTo(3000));
      expect(immersive.reapplyDelay.inMilliseconds, kImmersiveReapplyMs);
      expect(immersive.resumeReapplyDelay.inMilliseconds, kImmersiveResumeReapplyMs);
      expect(kImmersiveResumeBurstMs, [0, 150, 400, 1000, 2000]);
      expect(kImmersiveResumeBurstMs.last, lessThan(kImmersiveResumeWindowMs));
    });
  });
}
