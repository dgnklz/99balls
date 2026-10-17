import 'dart:io';
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 7.4.1: beş tema, benzersiz id, hepsi tam ve kendi ses kimliğiyle.
/// Orbitfall ücretsiz; Candy Burst (M3b), Pixel Drop (M3c), Abyss (M3d) ve
/// Ink & Paper (M3e) ücretli.
void main() {
  const expectedIds = {'orbitfall', 'candyburst', 'pixeldrop', 'abyss', 'inkpaper'};

  test('exactly five themes with unique, expected ids', () {
    final ids = ThemeRegistry.all.map((t) => t.id).toList();
    expect(ids, hasLength(5));
    expect(ids.toSet(), hasLength(5), reason: 'ids are unique');
    expect(ids.toSet(), expectedIds);
  });

  test('Orbitfall is the free default; every theme has its own sound identity', () {
    final orbitfall = ThemeRegistry.byId('orbitfall')!;
    expect(orbitfall.isFree, isTrue);
    expect(orbitfall.id, kDefaultThemeId);
    for (final theme in ThemeRegistry.all) {
      expect(theme.sounds.music, startsWith('${theme.id}/'), reason: 'own sound identity');
      for (final file in theme.sounds.sfxFiles) {
        expect(file, startsWith('${theme.id}/'), reason: file);
      }
      if (theme.id != 'orbitfall') expect(theme.isFree, isFalse, reason: theme.id);
    }
    // Her temanın kendi çizicisi var (yer tutucu yok).
    final rendererTypes = <Type>{};
    for (final theme in ThemeRegistry.all) {
      final renderer = theme.createRenderer(theme);
      rendererTypes.add(renderer.runtimeType);
      renderer.dispose();
    }
    expect(rendererTypes, hasLength(ThemeRegistry.all.length));
  });

  test('resolve falls back to Orbitfall for null or unknown ids', () {
    expect(ThemeRegistry.resolve(null).id, 'orbitfall');
    expect(ThemeRegistry.resolve('no-such-theme').id, 'orbitfall');
    expect(ThemeRegistry.resolve('abyss').id, 'abyss');
    expect(ThemeRegistry.fallback.id, 'orbitfall');
  });

  test('every theme has a localized name in en and tr', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final theme in ThemeRegistry.all) {
        expect(theme.displayName(l10n), isNotEmpty, reason: '${theme.id} $locale');
      }
    }
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), {'en', 'tr'});
  });

  test('every sound a theme references exists and has a declared duration', () {
    for (final theme in ThemeRegistry.all) {
      final sounds = theme.sounds;
      expect(File('assets/audio/${sounds.music}').existsSync(), isTrue,
          reason: '${theme.id} music');
      for (final key in SfxKey.values) {
        final files = sounds.sfx[key];
        expect(files, isNotNull, reason: '${theme.id} $key');
        expect(files, isNotEmpty, reason: '${theme.id} $key');
      }
      for (final file in sounds.sfxFiles) {
        expect(File('assets/audio/$file').existsSync(), isTrue, reason: file);
        expect(sounds.durationsMs[file], isNotNull, reason: file);
      }
    }
  });

  test('every audio folder a theme uses is bundled in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final theme in ThemeRegistry.all) {
      final folder = theme.sounds.music.split('/').first;
      expect(pubspec, contains('- assets/audio/$folder/'), reason: theme.id);
    }
  });

  test('every theme renderer can be created, updated, painted and disposed', () {
    for (final theme in ThemeRegistry.all) {
      final renderer = theme.createRenderer(theme);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      renderer
        ..update(1 / 60)
        ..paintBackground(canvas)
        ..paintTarget(canvas, 100, 200, 12)
        ..paintBall(canvas, 50, 600);
      recorder.endRecording().dispose();
      renderer.dispose();
    }
  });
}
