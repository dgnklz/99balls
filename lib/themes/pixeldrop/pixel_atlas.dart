import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Atlastaki tek sprite: atlas içindeki piksel dikdörtgeni ve çapaya göre
/// sol üst köşesi (gu, ölçek 1'de).
class PixelSprite {
  final Rect src;
  final Offset origin;

  const PixelSprite(this.src, this.origin);

  double get widthPx => src.width;
}

/// Pixel Drop'un beyaz maske sprite'larını tek resimde toplar; hepsi tek
/// `drawRawAtlas` çağrısıyla, renk başına boyanarak (BlendMode.modulate)
/// çizilir.
///
/// Keskinlik: atlas cihaz çözünürlüğünde ([pxPerGu]) üretilir ve her hücrenin
/// kenarı tam piksele yuvarlanır; yerleştirmede sol üst köşe ve ölçek de cihaz
/// pikseline oturtulur ([AtlasBatch.add], [snapScale]). Sprite'lar
/// FilterQuality.none ile 1:1 çizilir: kayan nesnelerde hücreler titremez.
class PixelAtlas {
  static const int _padPx = 1;
  static const int _maxRowPx = 1024;

  final double pxPerGu;
  final Image image;
  final List<PixelSprite> sprites;

  PixelAtlas._(this.pxPerGu, this.image, this.sprites);

  /// [shapes]: her sprite için hücreler (gu, çapa = orijin). Sıra korunur.
  factory PixelAtlas.build(double pxPerGu, List<List<Rect>> shapes) {
    final sprites = <PixelSprite>[];
    final placed = <(List<Rect>, Rect, Offset)>[];
    var x = _padPx;
    var y = _padPx;
    var rowHeight = 0;
    var atlasWidth = 0;
    for (final cells in shapes) {
      final bounds = cells.reduce((a, b) => a.expandToInclude(b));
      final w = (bounds.width * pxPerGu).round();
      final h = (bounds.height * pxPerGu).round();
      if (x + w + _padPx > _maxRowPx && x > _padPx) {
        x = _padPx;
        y += rowHeight + _padPx;
        rowHeight = 0;
      }
      final src = Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
      sprites.add(PixelSprite(src, bounds.topLeft));
      placed.add((cells, bounds, Offset(x.toDouble(), y.toDouble())));
      x += w + _padPx;
      rowHeight = math.max(rowHeight, h);
      atlasWidth = math.max(atlasWidth, x);
    }
    final atlasHeight = y + rowHeight + _padPx;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    for (final (cells, bounds, at) in placed) {
      for (final c in cells) {
        canvas.drawRect(
          Rect.fromLTRB(
            at.dx + ((c.left - bounds.left) * pxPerGu).roundToDouble(),
            at.dy + ((c.top - bounds.top) * pxPerGu).roundToDouble(),
            at.dx + ((c.right - bounds.left) * pxPerGu).roundToDouble(),
            at.dy + ((c.bottom - bounds.top) * pxPerGu).roundToDouble(),
          ),
          white,
        );
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(atlasWidth, atlasHeight);
    picture.dispose();
    return PixelAtlas._(pxPerGu, image, List.unmodifiable(sprites));
  }

  /// Ölçeği, [sprite] cihazda tam piksel genişlikte kalacak şekilde yuvarlar.
  static double snapScale(PixelSprite sprite, double scale) {
    if (scale == 1) return 1;
    final w = sprite.widthPx;
    return math.max(1, (w * scale).round()) / w;
  }

  void dispose() => image.dispose();
}

/// drawRawAtlas için önceden ayrılmış diziler (karede tahsis yok).
class AtlasBatch {
  final int capacity;
  final Float32List _rst;
  final Float32List _rects;
  final Int32List _colors;
  int length = 0;

  AtlasBatch(this.capacity)
      : _rst = Float32List(capacity * 4),
        _rects = Float32List(capacity * 4),
        _colors = Int32List(capacity);

  void clear() => length = 0;

  /// [sprite]'ı çapa (ax, ay) gu'ya [scale] ölçekle ekler. Ölçek sprite'ın
  /// cihazdaki genişliği tam piksel olacak şekilde yuvarlanır
  /// ([PixelAtlas.snapScale]); sol üst köşe cihaz pikseline oturur.
  void add(PixelSprite sprite, double ax, double ay, double rawScale, int argb, double pxPerGu) {
    if (length >= capacity) return;
    final scale = PixelAtlas.snapScale(sprite, rawScale);
    final i = length * 4;
    _rst[i] = scale / pxPerGu;
    _rst[i + 1] = 0;
    _rst[i + 2] = ((ax + sprite.origin.dx * scale) * pxPerGu).roundToDouble() / pxPerGu;
    _rst[i + 3] = ((ay + sprite.origin.dy * scale) * pxPerGu).roundToDouble() / pxPerGu;
    final src = sprite.src;
    _rects[i] = src.left;
    _rects[i + 1] = src.top;
    _rects[i + 2] = src.right;
    _rects[i + 3] = src.bottom;
    _colors[length] = argb;
    length++;
  }

  /// Toplananları tek çağrıda çizer ve boşaltır.
  void flush(Canvas canvas, PixelAtlas atlas, Paint paint) {
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
