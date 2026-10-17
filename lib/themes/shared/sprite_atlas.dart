import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Atlastaki tek sprite: atlas içindeki piksel dikdörtgeni ve çapaya göre
/// kapladığı alan (gu, ölçek 1'de).
class AtlasSprite {
  final Rect src;
  final Rect bounds;

  const AtlasSprite(this.src, this.bounds);
}

/// Bir sprite'ın tarifi: çapaya göre alanı (gu) ve beyaz maskeyi gu
/// koordinatlarında (orijin = çapa) çizen işlev.
typedef SpriteSpec = (Rect bounds, void Function(Canvas canvas) draw);

/// Pürüzsüz (kenar yumuşatmalı) beyaz maske sprite'larını cihaz
/// çözünürlüğünde tek resimde toplar. Hepsi [SpriteBatch] ile tek
/// `drawRawAtlas` çağrısında, renk başına boyanarak (BlendMode.modulate) ve
/// çift doğrusal örneklemeyle çizilir. Pahalı işlemler (ör. MaskFilter.blur)
/// yalnızca üretimde yapılır; karede bulanıklık yoktur (PRD 7.4.1, M3p).
///
/// Piksel temasının `PixelAtlas`'ından farkı: konum ve ölçek cihaz pikseline
/// oturtulmaz (pürüzsüz biçimler), sprite'lar arasında örnekleme taşmasına
/// karşı boşluk vardır ve her sprite kendi hücresine kırpılır.
class SpriteAtlas {
  static const int _padPx = 2;
  static const int _maxRowPx = 1024;

  final double pxPerGu;
  final Image image;
  final List<AtlasSprite> sprites;

  SpriteAtlas._(this.pxPerGu, this.image, this.sprites);

  /// [specs] sırası korunur. Her sprite'ın alanı, cihazda tam piksel
  /// genişlik ve yükseklik kaplayacak şekilde sağa/aşağı genişletilir.
  factory SpriteAtlas.build(double pxPerGu, List<SpriteSpec> specs) {
    final sprites = <AtlasSprite>[];
    final origins = <Offset>[];
    var x = _padPx;
    var y = _padPx;
    var rowHeight = 0;
    var atlasWidth = 0;
    for (final (bounds, _) in specs) {
      final w = (bounds.width * pxPerGu).ceil();
      final h = (bounds.height * pxPerGu).ceil();
      if (x + w + _padPx > _maxRowPx && x > _padPx) {
        x = _padPx;
        y += rowHeight + _padPx;
        rowHeight = 0;
      }
      sprites.add(AtlasSprite(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
        Rect.fromLTWH(bounds.left, bounds.top, w / pxPerGu, h / pxPerGu),
      ));
      origins.add(Offset(x.toDouble(), y.toDouble()));
      x += w + _padPx;
      rowHeight = math.max(rowHeight, h);
      atlasWidth = math.max(atlasWidth, x);
    }
    final atlasHeight = y + rowHeight + _padPx;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (var i = 0; i < specs.length; i++) {
      final sprite = sprites[i];
      canvas
        ..save()
        ..clipRect(sprite.src)
        ..translate(origins[i].dx, origins[i].dy)
        ..scale(pxPerGu)
        ..translate(-sprite.bounds.left, -sprite.bounds.top);
      specs[i].$2(canvas);
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(math.max(1, atlasWidth), math.max(1, atlasHeight));
    picture.dispose();
    return SpriteAtlas._(pxPerGu, image, List.unmodifiable(sprites));
  }

  void dispose() => image.dispose();
}

/// drawRawAtlas için önceden ayrılmış diziler (karede tahsis yok).
class SpriteBatch {
  final int capacity;
  final Float32List _rst;
  final Float32List _rects;
  final Int32List _colors;
  int length = 0;

  SpriteBatch(this.capacity)
      : _rst = Float32List(capacity * 4),
        _rects = Float32List(capacity * 4),
        _colors = Int32List(capacity);

  /// [sprite]'ı çapa (x, y) gu'ya [scale] ölçekle, [argb] rengine boyanmış
  /// olarak ekler. Kapasite doluysa yok sayılır.
  void add(AtlasSprite sprite, double x, double y, double scale, int argb, double pxPerGu) {
    if (length >= capacity) return;
    final i = length * 4;
    _rst[i] = scale / pxPerGu;
    _rst[i + 1] = 0;
    _rst[i + 2] = x + sprite.bounds.left * scale;
    _rst[i + 3] = y + sprite.bounds.top * scale;
    final src = sprite.src;
    _rects[i] = src.left;
    _rects[i + 1] = src.top;
    _rects[i + 2] = src.right;
    _rects[i + 3] = src.bottom;
    _colors[length] = argb;
    length++;
  }

  /// [add] gibi, ama sprite çapa çevresinde (cos, sin) birim yönüne döndürülür
  /// (yönlü parçacıklar; açı yerine yön vektörü verilir, trig gerekmez).
  /// (cos, sin) = (1, 0) iken [add] ile aynıdır.
  void addRotated(AtlasSprite sprite, double x, double y, double scale, double cos, double sin,
      int argb, double pxPerGu) {
    if (length >= capacity) return;
    final i = length * 4;
    final b = sprite.bounds;
    _rst[i] = scale * cos / pxPerGu;
    _rst[i + 1] = scale * sin / pxPerGu;
    _rst[i + 2] = x + scale * (cos * b.left - sin * b.top);
    _rst[i + 3] = y + scale * (sin * b.left + cos * b.top);
    final src = sprite.src;
    _rects[i] = src.left;
    _rects[i + 1] = src.top;
    _rects[i + 2] = src.right;
    _rects[i + 3] = src.bottom;
    _colors[length] = argb;
    length++;
  }

  /// Toplananları tek çağrıda çizer ve boşaltır.
  void flush(Canvas canvas, SpriteAtlas atlas, Paint paint) {
    if (length == 0) return;
    canvas.drawRawAtlas(
      atlas.image,
      Float32List.sublistView(_rst, 0, length * 4),
      Float32List.sublistView(_rects, 0, length * 4),
      Int32List.sublistView(_colors, 0, length),
      BlendMode.modulate,
      null,
      paint,
    );
    length = 0;
  }
}
