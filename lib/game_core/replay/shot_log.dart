import 'dart:convert';
import 'dart:typed_data';

import '../constants.dart';

/// Bir atışın kaydı: (adım_no, vx, vy) (PRD Bölüm 11.8).
class ShotRecord {
  final int step;
  final int vx;
  final int vy;

  const ShotRecord(this.step, this.vx, this.vy);

  @override
  bool operator ==(Object other) =>
      other is ShotRecord && other.step == step && other.vx == vx && other.vy == vy;

  @override
  int get hashCode => Object.hash(step, vx, vy);

  @override
  String toString() => 'ShotRecord($step, $vx, $vy)';
}

/// Bozuk ya da sınır dışı tekrar kaydı.
class ReplayFormatException implements Exception {
  final String message;

  const ReplayFormatException(this.message);

  @override
  String toString() => 'ReplayFormatException: $message';
}

const int _varintPayloadBits = 7;
const int _varintPayloadMask = 0x7F;
const int _varintContinue = 0x80;
const int _intBits = 64;
const int _signShift = 63;

/// Kodlama: [sürüm][atış sayısı][her atış: adım farkı, zigzag(vx), zigzag(vy)],
/// tüm tamsayılar LEB128 varint; sonuç base64.
String encodeShots(List<ShotRecord> shots) {
  final out = BytesBuilder(copy: false)..addByte(kReplayFormatVersion);
  _writeVarint(out, shots.length);
  var previousStep = 0;
  for (final shot in shots) {
    if (shot.step < previousStep) {
      throw ArgumentError('shots must be ordered by step');
    }
    _writeVarint(out, shot.step - previousStep);
    _writeVarint(out, _zigzag(shot.vx));
    _writeVarint(out, _zigzag(shot.vy));
    previousStep = shot.step;
  }
  return base64Encode(out.takeBytes());
}

/// [encodeShots]'un tersi. Bozuk girdi için [ReplayFormatException] fırlatır.
List<ShotRecord> decodeShots(String encoded) {
  if (encoded.length > kReplayMaxBytes) {
    throw const ReplayFormatException('replay exceeds kReplayMaxBytes');
  }
  final Uint8List bytes;
  try {
    bytes = base64Decode(encoded);
  } on FormatException {
    throw const ReplayFormatException('invalid base64');
  }
  final reader = _ByteReader(bytes);
  if (reader.readByte() != kReplayFormatVersion) {
    throw const ReplayFormatException('unsupported version');
  }
  final count = reader.readVarint();
  final shots = <ShotRecord>[];
  var step = 0;
  for (var i = 0; i < count; i++) {
    step += reader.readVarint();
    final vx = _unzigzag(reader.readVarint());
    final vy = _unzigzag(reader.readVarint());
    shots.add(ShotRecord(step, vx, vy));
  }
  if (!reader.isAtEnd) {
    throw const ReplayFormatException('trailing bytes');
  }
  return shots;
}

int _zigzag(int n) => (n << 1) ^ (n >> _signShift);

int _unzigzag(int z) => (z >>> 1) ^ -(z & 1);

void _writeVarint(BytesBuilder out, int value) {
  var v = value;
  while ((v & ~_varintPayloadMask) != 0) {
    out.addByte((v & _varintPayloadMask) | _varintContinue);
    v >>>= _varintPayloadBits;
  }
  out.addByte(v);
}

class _ByteReader {
  final Uint8List _bytes;
  int _pos = 0;

  _ByteReader(this._bytes);

  bool get isAtEnd => _pos == _bytes.length;

  int readByte() {
    if (_pos >= _bytes.length) {
      throw const ReplayFormatException('truncated');
    }
    return _bytes[_pos++];
  }

  int readVarint() {
    var result = 0;
    for (var shift = 0; shift < _intBits; shift += _varintPayloadBits) {
      final byte = readByte();
      result |= (byte & _varintPayloadMask) << shift;
      if (byte & _varintContinue == 0) return result;
    }
    throw const ReplayFormatException('varint too long');
  }
}
