import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Uygulama ikonu (kaynak assets/brand/app-icon-master.png, tools/icon/make_icon.py),
/// mağaza ikonları ve marka splash'ı.
/// PNG IHDR: genişlik/yükseklik (16/20. bayt), renk tipi (25. bayt):
/// 2 = RGB (alfa yok), 6 = RGBA.
const int _rgb = 2;
const int _rgba = 6;
const int _size = 1024;

/// Android adaptive ön planı: master bu oranda, ortada; kenar geçişi (make_icon.py).
const double _foregroundScale = 0.78;
const int _featherPx = 24;

({int width, int height, int colorType}) _png(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.sublist(1, 4), 'PNG'.codeUnits, reason: path);
  final data = ByteData.sublistView(bytes);
  return (width: data.getUint32(16), height: data.getUint32(20), colorType: bytes[25]);
}

Future<(ByteData, int)> _rgbaPixels(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (data!, frame.image.width);
}

int _alpha(ByteData data, int width, int x, int y) => data.getUint8((y * width + x) * 4 + 3);

void main() {
  testWidgets('master design exists (1024, full square)', (tester) async {
    // Not: dosya .png uzantılı ama içerik JPEG; PNG başlığı değil, çözülmüş
    // görüntü denetlenir (Pillow da içeriğe göre açar).
    await tester.runAsync(() async {
      final (_, width) = await _rgbaPixels('assets/brand/app-icon-master.png');
      expect(width, _size);
    });
  });

  test('iOS: 1024 with no alpha channel', () {
    final ios = _png('assets/icon/ios.png');
    expect((ios.width, ios.height), (_size, _size));
    expect(ios.colorType, _rgb);
  });

  test('Android: legacy square, gradient background and transparent foreground (1024)', () {
    for (final name in ['android_legacy', 'android_background', 'android_foreground']) {
      final png = _png('assets/icon/$name.png');
      expect((png.width, png.height), (_size, _size), reason: name);
    }
    expect(_png('assets/icon/android_foreground.png').colorType, _rgba);
  });

  testWidgets('Android foreground: content within the central 78%, corners transparent',
      (tester) async {
    await tester.runAsync(() async {
      final (data, width) = await _rgbaPixels('assets/icon/android_foreground.png');
      final margin = (_size * (1 - _foregroundScale) / 2).floor();
      // Köşeler ve %78 karenin dışı tamamen şeffaf.
      for (final (x, y) in [(0, 0), (_size - 1, 0), (0, _size - 1), (_size - 1, _size - 1)]) {
        expect(_alpha(data, width, x, y), 0, reason: 'corner ($x, $y)');
      }
      for (var i = 0; i < _size; i += 8) {
        for (final (x, y) in [(i, margin - 1), (i, _size - margin), (margin - 1, i), (_size - margin, i)]) {
          expect(_alpha(data, width, x, y), 0, reason: 'outside 78% at ($x, $y)');
        }
      }
      // Merkez opak; kenara doğru yumuşak geçiş: geçiş bandının ortası yarı saydam.
      expect(_alpha(data, width, _size ~/ 2, _size ~/ 2), 255);
      final edge = _alpha(data, width, _size ~/ 2, margin + _featherPx);
      expect(edge, inExclusiveRange(0, 255), reason: 'feathered edge');
    });
  });

  test('store icons: Google Play 512 (32-bit) and App Store 1024 (no alpha)', () {
    final play = _png('assets/store/play_icon_512.png');
    expect((play.width, play.height), (512, 512));
    expect(play.colorType, _rgba, reason: '32-bit PNG');
    final appStore = _png('assets/store/appstore_icon_1024.png');
    expect((appStore.width, appStore.height), (_size, _size));
    expect(appStore.colorType, _rgb);
  });

  test('brand splash logo exists (512)', () {
    final logo = _png('assets/brand/splash-logo-circular.png');
    expect((logo.width, logo.height), (512, 512));
  });

  group('pubspec configuration', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('launcher icons are configured per platform with separate paths, no web', () {
      expect(pubspec, contains('flutter_launcher_icons:'));
      expect(pubspec, contains('image_path_android: "assets/icon/android_legacy.png"'));
      expect(pubspec, contains('adaptive_icon_foreground: "assets/icon/android_foreground.png"'));
      expect(pubspec, contains('adaptive_icon_background: "assets/icon/android_background.png"'));
      expect(pubspec, contains('image_path_ios: "assets/icon/ios.png"'));
      expect(pubspec, contains('remove_alpha_ios: true'));
      expect(RegExp(r'web:\s*\n\s*generate: false').hasMatch(pubspec), isTrue);
    });

    test('native splash matches the brand config, incl. Android 12, no web', () {
      expect(pubspec, contains('flutter_native_splash:'));
      expect(pubspec, contains('color: "#000000"'));
      expect(pubspec, contains('image: "assets/brand/splash-logo-circular.png"'));
      expect(pubspec, contains('android_12:'));
      expect(pubspec, contains('icon_background_color: "#000000"'));
      expect(pubspec, contains('web: false'));
    });

    test('web splash files are not present', () {
      expect(Directory('web/splash').existsSync(), isFalse);
    });

    test('store, icon and brand sources are not bundled into the app', () {
      final lines = pubspec.split('\n').map((l) => l.trimRight()).toList();
      final start = lines.indexOf('  assets:');
      expect(start, isNonNegative, reason: 'flutter assets block');
      final bundled = lines.skip(start + 1).takeWhile((l) => l.startsWith('    - ')).toList();
      expect(bundled, isNotEmpty);
      for (final entry in bundled) {
        expect(entry, isNot(contains('assets/store')));
        expect(entry, isNot(contains('assets/icon')));
        expect(entry, isNot(contains('assets/brand')));
      }
    });
  });
}
