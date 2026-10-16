import 'dart:typed_data';

/// 64-bit FNV-1a karması; determinizm testleri için durum özeti üretir.
class StateHasher {
  static const int _offsetBasis = 0xCBF29CE484222325;
  static const int _prime = 0x100000001B3;
  static const int _bytesPerInt = 8;
  static const int _bitsPerByte = 8;
  static const int _byteMask = 0xFF;

  final ByteData _scratch = ByteData(_bytesPerInt);
  int _hash = _offsetBasis;

  int get value => _hash;

  void addInt(int value) {
    for (var i = 0; i < _bytesPerInt; i++) {
      _hash ^= (value >>> (i * _bitsPerByte)) & _byteMask;
      _hash *= _prime;
    }
  }

  /// Double'ın ham IEEE-754 bitlerini ekler (yuvarlama farkı bile karmayı değiştirir).
  void addDouble(double value) {
    _scratch.setFloat64(0, value);
    addInt(_scratch.getInt64(0));
  }

  void addBool(bool value) => addInt(value ? 1 : 0);
}
