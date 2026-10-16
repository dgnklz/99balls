import 'dart:io';
import 'dart:math' as math;

import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wav_reader.dart';

/// Orbitfall sesleri (tools/audio ile üretilir): PRD 8.1 ve M3a kararları.
const String _dir = 'assets/audio/orbitfall';
const int _sfxRate = 44100;
const int _musicRate = 22050;
const int _int16Max = 32767;
const double _peakDbfs = -3.0;
const double _peakTolerance = 0.05;
const int _maxSfxMs = 1000;
const int _budgetBytes = 2 * 1024 * 1024;

/// Döngü sınırında başı ve sonu: tam ölçeğin %1'inden küçük.
const int _loopEdgeThreshold = 328;

double _peakDb(Wav w) {
  var peak = 0;
  for (final s in w.samples) {
    if (s.abs() > peak) peak = s.abs();
  }
  return 20 * math.log(peak / _int16Max) / math.ln10;
}

void main() {
  final files = Directory(_dir).listSync().whereType<File>().where((f) => f.path.endsWith('.wav'));

  test('every WAV is PCM 16-bit mono', () {
    expect(files, isNotEmpty);
    for (final f in files) {
      final w = Wav.read(f.path);
      expect(w.format, 1, reason: f.path);
      expect(w.channels, 1, reason: f.path);
      expect(w.bitsPerSample, 16, reason: f.path);
    }
  });

  test('SFX: 44.1 kHz, ≤ 1 s, peak −3 dBFS, durations match the theme', () {
    for (final entry in orbitfallSounds.durationsMs.entries) {
      final w = Wav.read('assets/audio/${entry.key}');
      expect(w.sampleRate, _sfxRate, reason: entry.key);
      expect(w.durationMs, lessThanOrEqualTo(_maxSfxMs), reason: entry.key);
      expect(w.durationMs.round(), entry.value, reason: '${entry.key} declared duration');
      expect(_peakDb(w), closeTo(_peakDbfs, _peakTolerance), reason: entry.key);
    }
  });

  test('music: 22.05 kHz mono loop of ~32 s that starts and ends at a zero crossing', () {
    final w = Wav.read('assets/audio/${orbitfallSounds.music}');
    expect(w.sampleRate, _musicRate);
    expect(w.durationMs, inInclusiveRange(30000, 34000));
    expect(_peakDb(w), lessThanOrEqualTo(_peakDbfs + _peakTolerance));
    final first = w.samples.first;
    final last = w.samples.last;
    expect(first.abs(), lessThan(_loopEdgeThreshold), reason: 'start near zero');
    expect(last.abs(), lessThan(_loopEdgeThreshold), reason: 'end near zero');
    expect((last - first).abs(), lessThan(_loopEdgeThreshold), reason: 'seamless wrap');
  });

  test('no orphan files: every WAV is referenced by the theme', () {
    final referenced = {
      orbitfallSounds.music,
      ...orbitfallSounds.sfxFiles,
    }.map((p) => p.split('/').last).toSet();
    final onDisk = files.map((f) => f.uri.pathSegments.last).toSet();
    expect(onDisk, referenced);
  });

  test('theme audio fits the ~2 MB budget', () {
    final total = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThanOrEqualTo(_budgetBytes));
  });
}
