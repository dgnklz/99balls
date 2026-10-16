import 'dart:io';
import 'dart:typed_data';

/// Testler için basit PCM WAV okuyucu (RIFF/WAVE, fmt + data parçaları).
class Wav {
  final int format;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final Int16List samples;
  final int fileBytes;

  Wav._(this.format, this.channels, this.sampleRate, this.bitsPerSample, this.samples,
      this.fileBytes);

  double get durationMs => samples.length * 1000 / sampleRate;

  static Wav read(String path) {
    final bytes = File(path).readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') throw FormatException('not a WAV: $path');

    int? format, channels, rate, bits;
    Int16List? samples;
    var pos = 12;
    while (pos + 8 <= bytes.length) {
      final id = tag(pos);
      final size = data.getUint32(pos + 4, Endian.little);
      final body = pos + 8;
      if (id == 'fmt ') {
        format = data.getUint16(body, Endian.little);
        channels = data.getUint16(body + 2, Endian.little);
        rate = data.getUint32(body + 4, Endian.little);
        bits = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        final count = size ~/ 2;
        samples = Int16List(count);
        for (var i = 0; i < count; i++) {
          samples[i] = data.getInt16(body + i * 2, Endian.little);
        }
      }
      pos = body + size + (size.isOdd ? 1 : 0);
    }
    if (format == null || samples == null) throw FormatException('missing chunks: $path');
    return Wav._(format, channels!, rate!, bits!, samples, bytes.length);
  }
}
