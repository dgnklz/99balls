import 'dart:io';
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 7.4.1: beş tema, benzersiz id, Orbitfall ücretsiz ve tam, diğerleri yer tutucu.
void main() {
  const expectedIds = {'orbitfall', 'candybust', 'pixeldrop', 'abyss', 'inkpaper'};

  test('exactly five themes with unique, expected ids', () {
    final ids = ThemeRegistry.all.map((t) => t.id).toList();
    expect(ids, hasLength(5));
    expect(ids.toSet(), hasLength(5), reason: 'ids are unique');
    expect(ids.toSet(), expectedIds);
  });

  test('Orbitfall is free and complete; the other four are marked placeholders', () {
    final orbitfall = ThemeRegistry.byId('orbitfall')!;
    expect(orbitfall.isFree, isTrue);
    expect(orbitfall.isPlaceholder, isFalse);
    expect(orbitfall.id, kDefaultThemeId);
    for (final theme in ThemeRegistry.all.where((t) => t.id != 'orbitfall')) {
      expect(theme.isPlaceholder, isTrue, reason: theme.id);
      expect(theme.isFree, isFalse, reason: theme.id);
    }
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
