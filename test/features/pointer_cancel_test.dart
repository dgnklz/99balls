import 'package:balls_99/app/immersive_mode.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/features/game/game_screen.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistem hareketleriyle çakışan dokunuşlar atış yapmamalı:
/// - kenar şeridinde başlayan dokunuş hiç nişan başlatmaz;
/// - platform dokunmayı iptal ederse (pointerCancel), çubuklar görünür olursa
///   ya da odak kaybolursa aktif nişan iptal edilir.
/// Test yüzeyi 800×600 mantıksal piksel.
void main() {
  const aimDrag = Offset(-40, 120);
  const center = Offset(400, 300);

  Future<BallGame> pumpGame(WidgetTester tester, {ImmersiveMode? immersive}) async {
    SharedPreferences.setMockInitialValues({PrefsRepository.keyTutorialSeen: true});
    final prefs = await SharedPreferences.getInstance();
    late BallGame game;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
          if (immersive != null) immersiveModeProvider.overrideWithValue(immersive),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(gameFactory: () => game = BallGame(seed: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return game;
  }

  /// Başla, ortaya doğru nişan çek, bırak.
  Future<void> dragFrom(WidgetTester tester, Offset start, {Offset by = aimDrag}) async {
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(by);
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  void expectNoShot(BallGame game, String reason) {
    expect(game.aim.isTracking, isFalse, reason: reason);
    expect(game.session.shots, isEmpty, reason: reason);
    expect(game.session.phase, GamePhase.ready, reason: reason);
  }

  testWidgets('touches starting in an edge strip never aim or fire', (tester) async {
    final game = await pumpGame(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final strips = {
      'top': const Offset(400, kEdgeGuardTopDp - 2),
      'bottom': Offset(400, size.height - kEdgeGuardBottomDp + 2),
      'left': const Offset(kEdgeGuardSideDp - 2, 300),
      'right': Offset(size.width - kEdgeGuardSideDp + 2, 300),
    };
    for (final MapEntry(key: edge, value: start) in strips.entries) {
      // Şeritte başla, ortaya sürükle: nişan çizgisi de yok.
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(center + aimDrag);
      await tester.pump();
      expect(game.aim.current, isNull, reason: edge);
      await gesture.moveBy(aimDrag);
      await tester.pump();
      expect(game.aim.current, isNull, reason: edge);
      await gesture.up();
      await tester.pump();
      expectNoShot(game, edge);
    }

    // Şerit dışında başlayan normal sürükleme atış yapar.
    await dragFrom(tester, center);
    expect(game.session.shots, hasLength(1));
  });

  testWidgets('a drag starting in the middle may end in an edge strip', (tester) async {
    final game = await pumpGame(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Ortadan başlayıp alt şeride kadar aşağı çek.
    await dragFrom(tester, center, by: Offset(-40, size.height - center.dy - 2));
    expect(game.session.shots, hasLength(1));
  });

  testWidgets('a cancelled drag fires nothing; the next drag works', (tester) async {
    final game = await pumpGame(tester);
    final drag = await tester.startGesture(center);
    await drag.moveBy(aimDrag);
    await tester.pump();
    expect(game.aim.current, isNotNull, reason: 'aiming while dragging');
    await drag.cancel();
    await tester.pump();
    expectNoShot(game, 'cancelled');

    await dragFrom(tester, center);
    expect(game.session.shots, hasLength(1));
    expect(game.session.phase, isNot(GamePhase.ready));
  });

  testWidgets('system bars becoming visible cancel the active aim', (tester) async {
    final immersive = ImmersiveMode(setMode: () async {});
    final game = await pumpGame(tester, immersive: immersive);
    final drag = await tester.startGesture(center);
    await drag.moveBy(aimDrag);
    await tester.pump();
    expect(game.aim.current, isNotNull);

    await immersive.onSystemUiChange(true);
    await drag.moveBy(const Offset(0, 10));
    await tester.pump();
    expect(game.aim.current, isNull, reason: 'cancelled pointer is ignored');
    await drag.up();
    await tester.pump();
    expectNoShot(game, 'bars shown');

    await dragFrom(tester, center);
    expect(game.session.shots, hasLength(1), reason: 'next drag works');
    // Bekleyen yeniden gizleme zamanlayıcısı bitsin.
    await tester.pump(const Duration(milliseconds: kImmersiveReapplyMs));
  });

  testWidgets('losing focus (inactive) cancels the active aim', (tester) async {
    final game = await pumpGame(tester);
    final drag = await tester.startGesture(center);
    await drag.moveBy(aimDrag);
    await tester.pump();
    expect(game.aim.current, isNotNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await drag.up();
    await tester.pump();
    expectNoShot(game, 'focus lost');
  });
}
