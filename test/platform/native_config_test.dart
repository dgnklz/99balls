import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Yerel tam ekran ve splash çubuk rengi yapılandırması.
const _styleDirs = ['values', 'values-night', 'values-v31', 'values-night-v31'];

String _style(String xml, String name) {
  final match = RegExp('<style name="$name"[^>]*>(.*?)</style>', dotAll: true).firstMatch(xml);
  expect(match, isNotNull, reason: name);
  return match!.group(1)!;
}

void main() {
  for (final dir in _styleDirs) {
    test('$dir: splash bars black, cutout short edges', () {
      final xml = File('android/app/src/main/res/$dir/styles.xml').readAsStringSync();
      final launch = _style(xml, 'LaunchTheme');
      expect(launch, contains('<item name="android:windowDrawsSystemBarBackgrounds">true</item>'));
      expect(launch, contains('<item name="android:statusBarColor">#000000</item>'));
      expect(launch, contains('<item name="android:navigationBarColor">#000000</item>'));
      expect(launch, contains('<item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>'));
      final normal = _style(xml, 'NormalTheme');
      expect(normal, contains('<item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>'));
    });
  }

  test('MainActivity re-hides system bars on focus and sets short-edges cutout mode', () {
    final kt = File('android/app/src/main/kotlin/com/example/balls_99/MainActivity.kt')
        .readAsStringSync();
    expect(kt, contains('override fun onWindowFocusChanged(hasFocus: Boolean)'));
    // Arka plandan dönüşte hemen ve yerleşimden sonra bir kez daha gizler.
    expect(kt, contains('override fun onResume()'));
    expect(kt, contains('window.decorView.post { hideSystemBars() }'));
    expect(kt, contains('WindowInsets.Type.systemBars()'));
    expect(kt, contains('BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE'));
    expect(kt, contains('SYSTEM_UI_FLAG_IMMERSIVE_STICKY'));
    expect(kt, contains('LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES'));
  });

  test('iOS: status bar hidden', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(RegExp(r'<key>UIStatusBarHidden</key>\s*<true/>').hasMatch(plist), isTrue);
  });
}
