import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/app/edge_guard.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/features/game/game_screen.dart';
import 'package:balls_99/features/game/widgets/boost_button.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/fast_forward.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boost butonu: uzun uçuşta belirir, basışı nişan/atış sayılmaz, uçuş bitince
/// kaybolur (solarken basışı yutar), kenar koruma şeritlerinin içinde kalır.
/// Test yüzeyi 800×600 mantıksal piksel.
const double _frame = 1 / 60;

/// Yataya yakın atış: tek top boş tahtada uzun süre uçar.
const Shot _flat = Shot(1000, -90);
const double _margin = 0.5;

/// Aşağı çekiş = yukarı nişan (5.1).
const Offset _aimDrag = Offset(-40, 120);
const Duration _fade = Duration(milliseconds: kBoostFadeMs);
const Duration _swallowWindow = Duration(milliseconds: kBoostFadeMs + kBoostSwallowExtraMs);
const Duration _halfPulse = Duration(milliseconds: kBoostPulseMs ~/ 2);
const Duration _fullPulse = Duration(milliseconds: kBoostPulseMs);

/// Oyun döngüsünü [seconds] boyunca (ya da [until] sağlanana dek) elle ilerletir.
Future<void> _fly(WidgetTester tester, BallGame game, double seconds,
    {bool Function()? until}) async {
  final frames = (seconds / _frame).ceil();
  for (var i = 0; i < frames; i++) {
    if (until != null && until()) break;
    game.update(_frame);
  }
  await tester.pump();
}

Future<BallGame> _pumpGame(WidgetTester tester, {bool reduceMotion = false}) async {
  SharedPreferences.setMockInitialValues({PrefsRepository.keyTutorialSeen: true});
  final prefs = await SharedPreferences.getInstance();
  late BallGame game;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: GameScreen(
          gameFactory: () => game = BallGame(
            seed: 1,
            session: GameSession.forTest(board: Board(), initialBallCount: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return game;
}

/// Atış yapar ve butonun çıktığı ana kadar uçurur.
Future<void> _shootUntilBoost(WidgetTester tester, BallGame game) async {
  expect(game.session.tryShoot(_flat), isTrue);
  await _fly(tester, game, kFastForwardAfter + _margin);
  expect(game.boost.value, BoostState.off);
}

Finder get _button => find.byKey(const Key('boostButton'));

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
        find.descendant(of: find.byType(BoostButton), matching: find.byType(AnimatedOpacity)))
    .opacity;

bool _ignoring(WidgetTester tester) => tester
    .widget<IgnorePointer>(
        find.descendant(of: find.byType(BoostButton), matching: find.byType(IgnorePointer)).first)
    .ignoring;

double _scale(WidgetTester tester) => tester
    .widget<Transform>(
        find.descendant(of: find.byType(BoostButton), matching: find.byType(Transform)).first)
    .transform
    .getMaxScaleOnAxis();

void main() {
  testWidgets('hidden until flying lasts kFastForwardAfter, then fades in with one pulse',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final game = await _pumpGame(tester);
    expect(game.boost.value, BoostState.hidden);
    expect(_opacity(tester), 0);
    expect(_ignoring(tester), isTrue);

    expect(game.session.tryShoot(_flat), isTrue);
    await _fly(tester, game, kFastForwardAfter - _margin);
    expect(game.boost.value, BoostState.hidden, reason: 'not before the threshold');
    expect(_opacity(tester), 0);

    await _fly(tester, game, 2 * _margin);
    expect(game.boost.value, BoostState.off);
    expect(_ignoring(tester), isFalse);
    expect(_opacity(tester), 1);
    await tester.pump(_halfPulse);
    expect(_scale(tester), closeTo(kBoostPulseScale, 0.01), reason: 'one-shot pulse');
    await tester.pump(_fullPulse);
    expect(_scale(tester), 1, reason: 'no continuous animation');
    expect(find.bySemanticsLabel('Speed up'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reduce motion skips the pulse', (tester) async {
    final game = await _pumpGame(tester, reduceMotion: true);
    await _shootUntilBoost(tester, game);
    await tester.pump(_halfPulse);
    expect(_scale(tester), 1);
  });

  testWidgets('tapping toggles boost; presses on the button never aim or fire', (tester) async {
    final game = await _pumpGame(tester);
    await _shootUntilBoost(tester, game);
    await tester.pump(_fade);

    await tester.tap(_button);
    await tester.pump();
    expect(game.boost.value, BoostState.on);
    await tester.tap(_button);
    await tester.pump();
    expect(game.boost.value, BoostState.off);

    // Butonda başlayıp ortaya çekilen parmak: nişan yok, atış yok.
    final gesture = await tester.startGesture(tester.getCenter(_button));
    await gesture.moveTo(const Offset(400, 300));
    await gesture.moveBy(_aimDrag);
    await tester.pump();
    expect(game.aim.isTracking, isFalse);
    await gesture.up();
    await tester.pump();
    expect(game.aim.isTracking, isFalse);
    expect(game.session.shots, hasLength(1));
  });

  testWidgets('fades out when flying ends; a press while fading is swallowed, then '
      'touches pass through again; next flight starts hidden', (tester) async {
    final game = await _pumpGame(tester);
    await _shootUntilBoost(tester, game);
    await tester.pump(_fade);
    final center = tester.getCenter(_button);

    await _fly(tester, game, kFlightTimeoutSec.toDouble(),
        until: () => game.session.phase != GamePhase.flying);
    expect(game.boost.value, BoostState.hidden);
    expect(_opacity(tester), 0);
    expect(_ignoring(tester), isFalse, reason: 'still swallowing while fading');

    // Uçuş biterken butona basış: oyun ready'ye dönse bile nişan/atış yok.
    final late = await tester.startGesture(center);
    await _fly(tester, game, 1, until: () => game.session.phase == GamePhase.ready);
    expect(game.session.phase, GamePhase.ready);
    await late.moveBy(_aimDrag);
    await tester.pump();
    expect(game.aim.isTracking, isFalse);
    await late.up();
    await tester.pump();
    expect(game.session.shots, hasLength(1));

    // Pencere bittikten sonra aynı noktadan başlayan dokunuş oyuna geçer.
    await tester.pump(_swallowWindow);
    expect(_ignoring(tester), isTrue);
    final aim = await tester.startGesture(center);
    await aim.moveBy(_aimDrag);
    await tester.pump();
    expect(game.aim.isTracking, isTrue, reason: 'button gone: normal aiming');
    await aim.cancel();
    await tester.pump();

    // Sonraki atışta buton yine ancak kFastForwardAfter sonra çıkar.
    expect(game.session.tryShoot(_flat), isTrue);
    await _fly(tester, game, kFastForwardAfter - _margin);
    expect(game.boost.value, BoostState.hidden);
    await _fly(tester, game, 2 * _margin);
    expect(game.boost.value, BoostState.off);
  });

  testWidgets('restart hides the button and clears the boost', (tester) async {
    final game = await _pumpGame(tester);
    await _shootUntilBoost(tester, game);
    game.toggleBoost();
    expect(game.boost.value, BoostState.on);
    game.restart(2);
    expect(game.boost.value, BoostState.hidden);
  });

  group('boostButtonRect', () {
    const screens = {
      'small phone': (Size(360, 640), EdgeInsets.zero),
      'phone with notch': (Size(390, 844), EdgeInsets.only(top: 47)),
      'tall phone': (Size(412, 915), EdgeInsets.only(top: 24)),
      'short phone': (Size(375, 667), EdgeInsets.only(top: 20)),
      'tablet': (Size(768, 1024), EdgeInsets.only(top: 24)),
      'landscape tablet': (Size(1280, 800), EdgeInsets.only(top: 24)),
      'test surface': (Size(800, 600), EdgeInsets.zero),
    };

    for (final MapEntry(key: name, value: (screen, insets)) in screens.entries) {
      test(name, () {
        final fit = CanvasFit.compute(screen, insets);
        final guard = EdgeGuard.compute(screen, insets);
        final rect = boostButtonRect(fit, guard);
        final s = fit.scale;
        final canvas = fit.canvasRect;

        expect(rect.width, kBoostButtonSizeDp);
        expect(rect.height, kBoostButtonSizeDp);

        // Kenar koruma şeritlerinin en az kBoostButtonMarginDp içinde.
        final safe = guard.allowed.deflate(kBoostButtonMarginDp);
        expect(rect.left, greaterThanOrEqualTo(safe.left));
        expect(rect.top, greaterThanOrEqualTo(safe.top));
        expect(rect.right, lessThanOrEqualTo(safe.right));
        expect(rect.bottom, lessThanOrEqualTo(safe.bottom));

        // Oyun alanında: HUD'un altında, zemin çizgisinin ve atıcı topun üstünde.
        expect(rect.right, lessThanOrEqualTo(canvas.right - kBoostButtonMarginDp));
        expect(rect.top, greaterThan(canvas.top + kCeilingY * s));
        final floorY = canvas.top + kFloorY * s;
        expect(floorY - rect.bottom, greaterThanOrEqualTo(kBoostButtonBottomGapDp));
        final ballTop = canvas.top + (kLaunchY - kBallRadius) * s;
        expect(rect.bottom, lessThanOrEqualTo(ballTop - kBoostButtonMarginDp + 1e-9),
            reason: 'does not cover the launcher ball');

        // Zemin çubuğundaki debug tema seçiciyle çakışmaz.
        final picker = Rect.fromCenter(
          center: canvas.topLeft + const Offset(kDebugPickerX, kDebugPickerY) * s,
          width: kDebugPickerSize * s,
          height: kDebugPickerSize * s,
        );
        expect(rect.overlaps(picker), isFalse);
      });
    }
  });
}
