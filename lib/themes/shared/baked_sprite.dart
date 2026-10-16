import 'dart:ui';

/// Bir kez resme çevrilmiş (pişirilmiş) çizim. Pahalı işlemler (ör.
/// MaskFilter.blur) yalnızca pişirmede yapılır; karede tek `drawImageRect`
/// kalır. Görünüm aynıdır, çünkü resim cihaz çözünürlüğünde (piksel/gu)
/// üretilir.
///
/// [bounds]: resmin kapladığı alan (gu, orijin = çizim merkezi).
class BakedSprite {
  final Rect bounds;
  final Image image;
  final Rect _src;

  BakedSprite._(this.bounds, this.image)
      : _src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  /// [draw]'ı gu koordinatlarında (orijin merkez) kaydedip [pxPerGu]
  /// çözünürlükte resme çevirir.
  factory BakedSprite.record(Rect bounds, double pxPerGu, void Function(Canvas canvas) draw) {
    final width = (bounds.width * pxPerGu).ceil();
    final height = (bounds.height * pxPerGu).ceil();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(width / bounds.width, height / bounds.height)
      ..translate(-bounds.left, -bounds.top);
    draw(canvas);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return BakedSprite._(bounds, image);
  }

  /// (x, y) merkezli, [scale] ölçekli basar; [paint]'in alfası saydamlıktır.
  void draw(Canvas canvas, double x, double y, Paint paint, {double scale = 1}) {
    canvas.drawImageRect(
      image,
      _src,
      Rect.fromLTRB(
        x + bounds.left * scale,
        y + bounds.top * scale,
        x + bounds.right * scale,
        y + bounds.bottom * scale,
      ),
      paint,
    );
  }

  void dispose() => image.dispose();
}
