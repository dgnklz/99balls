/// Sunum, girdi ve arayüz sabitleri (PRD Bölüm 2.4, 4, 5.2, 7, 13).
///
/// Simülasyon sabitleri `lib/game_core/constants.dart` içindedir; tüm
/// koordinatlar 416×703 gu sanal tuvalindedir.
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../game_core/constants.dart';

// --- Kare döngüsü (PRD 2.3, 10.2) --------------------------------------------

/// Bir karede işlenecek en fazla simülasyon adımı; fazlası atılır.
const int kMaxStepsPerFrame = 8;

/// İlk karede (ve arka plandan dönüşte) kabul edilen en büyük dt (sn).
const double kFirstFrameMaxDt = 1 / 30;

// --- Uzun kuyrukta oyuncu kontrollü hızlanma (boost; yalnızca kare saati) ----

/// flying fazında bu kadar gerçek süre (sn) geçince boost butonu belirir.
/// Kendiliğinden hızlanma yoktur.
const double kFastForwardAfter = 8;

/// Kare saatinin en büyük çarpanı ve 1 ↔ en büyük arası rampa süresi (sn);
/// açarken ve kapatırken aynı rampa.
const int kFastForwardMax = 4;
const double kFastForwardRamp = 1.5;

/// Boost butonu (mantıksal piksel = dp): dokunma alanı, görünen daire,
/// kenar koruma şeritlerinden ve tuval kenarından boşluk.
const double kBoostButtonSizeDp = 56;
const double kBoostButtonVisualDp = 44;
const double kBoostButtonMarginDp = 8;

/// Zemin çizgisinden en az boşluk; ayrıca atıcı top çapı + [kBoostButtonMarginDp]
/// kadar yukarıda durur (zemindeki topları örtmesin).
const double kBoostButtonBottomGapDp = 16;

/// Belirme/kaybolma süresi ve kaybolduktan sonra dokunuşları yutmaya devam
/// ettiği ek süre (uçuş biterken basış nişana düşmesin).
const int kBoostFadeMs = 200;
const int kBoostSwallowExtraMs = 150;

/// İlk belirişte tek seferlik ölçek nabzı 1 → [kBoostPulseScale] → 1
/// (hareket azaltma açıksa atlanır).
const int kBoostPulseMs = 400;
const double kBoostPulseScale = 1.12;

/// "»" simgesi (iki chevron) ve kenar çizgisi.
const double kBoostIconSizeDp = 18;
const double kBoostIconStrokeDp = 2.5;
const double kBoostEdgeStrokeDp = 1.5;

/// Hızlanmada karede en fazla adım: 8 × çarpan, mutlak üst sınır 32.
const int kMaxStepsPerFrameFast = kMaxStepsPerFrame * kFastForwardMax;

// --- Nişan çizgisi (PRD 5.2) -------------------------------------------------

const double kGuideLength = 490;
const double kGuideDash = 12;
const double kGuideGap = 12.6;
const double kGuideStroke = 3;
const double kGuideOpacity = 0.9;

/// Çizginin saydamlaşarak bittiği son uzunluk.
const double kGuideFadeLength = 40;

/// Sonsuz yansımaya karşı segment sınırı.
const int kGuideMaxSegments = 64;

/// Bir segmentte üretilecek en fazla kesik parça (490 gu ≈ 21 parça).
const int kGuideMaxDashesPerSegment = 100;

/// Çizgi boyu rampası: ölü bölgeden çıkışta [kGuideMinLength], ölü bölgeden
/// [kGuideRampDistance] gu sonra tam [kGuideLength].
const double kGuideMinLength = 60;
const double kGuideRampDistance = 120;

// --- İnce nişan (görünüm katmanı, PRD 5.1 üzerine) ---------------------------

/// Ölü bölge histerezisi: nişan [kAimEnterDistance]'ta başlar, ancak
/// [kAimExitDistance]'ın altına inince kaybolur (sınırda yanıp sönmesin).
const double kAimEnterDistance = kAimDeadZone;
const double kAimExitDistance = 6;

/// Etkin nişan yarıçapının alt sınırı: kısa çekişte açı değişimi
/// L / kAimMinRadius kazancıyla uygulanır; 1 gu hareket ≤ atan(1/120) ≈ 0.48°.
const double kAimMinRadius = 120;

/// Nişan açısı `aimFromDrag`'a bu uzunlukta bir vektörle verilir
/// (shot = round(a·100) → yön çözünürlüğü ≈ 0.006°).
const double kAimShotLength = 100;

// --- Topların birleşmesi -----------------------------------------------------

/// İnen topların ilk inen topa kayma hızı (gu/sn). 1600 ile en uzak mesafe
/// (390 gu) collecting süresinden (0.25 sn) kısa sürer; yetişemeyen top
/// collecting bitince hedefe oturur.
const double kMergeSpeed = 1600;

// --- Nesne çizimi (PRD 4.3, 5.11, 7.1) ---------------------------------------

/// Atılan topun çizgi kalınlığı.
const double kBallStroke = 4.5;

/// Toplanabilir halkanın çizgi kalınlığı ve parlama bulanıklığı. Bulanıklık
/// karede değil, bir kez pişirilen parıltı resminde uygulanır (BakedSprite).
const double kPickupStroke = 5;
const double kPickupGlowBlur = 4;

/// Önceden pişirilen sprite'ların çözünürlüğü (piksel/gu): oyun gerçek
/// değeri (tuval genişliği × devicePixelRatio / kVirtualW) verene kadar ve
/// testlerde kullanılır.
const double kSpritePxPerGu = 3;

/// Parıltı resminde bulanıklığın kesilmeden sığması için kenar payı (sigma katı).
const double kGlowSpriteSigmas = 3;

/// Yıldızın dış yarıçapı / hedef yarıçapı ve iç köşe oranı.
const double kStarSizeRatio = 0.7;
const double kStarInnerRatio = 0.45;
const int kStarPoints = 5;

/// Hedef içindeki HP rakamı: 1–2 hane ve 3 hane yazı boyu.
const double kTargetFontSize = 24;
const double kTargetFontSize3Digits = 19;

/// 3 haneli sayının başladığı değer.
const int kThreeDigitThreshold = 100;

// --- HUD (PRD 4.5) -----------------------------------------------------------

const double kHudFontSize = 26;
const double kHudScoreX = 208;
const double kHudScoreY = 26;
const double kHudCounterX = 208;
const double kHudCounterY = 669;
const double kHudBallIconX = 39;
const double kHudBallIconY = 669;
const double kHudBallIconDiameter = 24;

// --- Oyun sonu (PRD 5.4, 7.2) ------------------------------------------------

/// Biten satırın yanıp sönme süresi ve sayısı.
const double kGameOverHighlightSec = 0.6;
const int kGameOverBlinkCount = 3;

/// Oyun sonu katmanının solarak açılma süresi.
const double kGameOverFadeSec = 0.35;

/// Duraklatma ve oyun sonu katmanı karartması (%60 siyah).
const double kOverlayScrimOpacity = 0.6;

// --- Öğretici (PRD 5.8) ------------------------------------------------------

const double kTutorialLoopSec = 2.4;

/// İlk basışta katmanın solma süresi ("hızla solar").
const double kTutorialFadeSec = 0.2;

/// Elin bir döngüde çektiği mesafe (gu, aşağı-sola).
const double kTutorialPullX = -60;
const double kTutorialPullY = 70;

/// Döngünün çekme kısmının oranı (kalanı bırakma ve bekleme).
const double kTutorialPullFraction = 0.6;

/// Öğretici katmanın yerleşimi (gu): metin, el ikonu ve nokta.
const double kTutorialTextY = 300;
const double kTutorialTextWidth = 340;
const double kTutorialTextSize = 22;
const double kTutorialHandX = 208;
const double kTutorialHandY = 430;
const double kTutorialIconSize = 48;
const double kTutorialDotRadius = 8;

// --- Geçici oyun sonu kartı (M4'te gerçek ekran gelecek) ---------------------

const double kOverlayCardWidth = 300;
const double kOverlayCardRadius = 14;
const double kOverlayCardPadding = 24;
const double kOverlayGap = 12;
const double kOverlayTitleSize = 32;
const double kOverlayLabelSize = 18;
const double kOverlayScoreSize = 56;
const double kOverlayButtonHeight = 52;
const double kOverlayButtonTextSize = 20;

// --- Arayüz (PRD 3.1) --------------------------------------------------------

/// Sistem yazı ölçeğinin üst sınırı.
const double kMaxTextScale = 1.15;

/// Tam ekran: sistem çubukları görünür hale gelirse bu kadar sonra yeniden
/// gizlenir (art arda olaylar tek zamanlayıcıda birleşir).
const int kImmersiveReapplyMs = 3000;

/// Kendi SystemChrome çağrımızın hemen ardından gelen sistem çubuğu olayları
/// bu süre içinde yok sayılır (kendi tetiklediğimiz değişiklik).
const int kImmersiveOwnEventWindowMs = 500;

/// Arka plandan dönüşte (`resumed`) hemen gizlemenin ardından bu anlarda
/// (ms) post-frame yeniden gizlenir; Android çubukları dönüş sırasında birkaç
/// kez yeniden gösterebilir.
const List<int> kImmersiveResumeBurstMs = [0, 150, 400, 1000, 2000];

/// Dönüş penceresi: `resumed`'dan sonraki bu süre içinde görünür olan çubuklar
/// [kImmersiveResumeReapplyMs] sonra gizlenir (dışında [kImmersiveReapplyMs]).
const int kImmersiveResumeWindowMs = 3000;

/// Dönüş penceresi içindeki yeniden gizleme gecikmesi.
const int kImmersiveResumeReapplyMs = 250;

/// Kenar koruma şeritleri (dp = Flutter mantıksal pikseli): bu şeritlerde
/// başlayan dokunuş sistem hareketidir (bildirim paneli, ana ekran, geri);
/// nişan hiç başlamaz. Üst şerit çentik/güvenli alan payının üstüne eklenir.
const double kEdgeGuardTopDp = 32;
const double kEdgeGuardBottomDp = 32;
const double kEdgeGuardSideDp = 24;

// --- Temalar (PRD 7.4.1) -----------------------------------------------------

/// v1'de tüm temalar açık (kilit sorusunun tek kapısı ThemeAccess).
const bool kAllThemesUnlocked = true;

/// Ücretsiz ve varsayılan tema; bilinmeyen/kilitli seçim buna düşer.
const String kDefaultThemeId = 'orbitfall';

/// Geliştirici araçları (tema seçici, yüksek HP tahtası): debug ve profile
/// yapıda açık, release'te asla.
const bool kDebugToolsEnabled = !kReleaseMode;

/// Yüksek HP debug tahtasının tur sayacı: 1'den 99 topa ortalama ~175 turda
/// varılır (satır başına %56 halka); HUD sayacı ve skor 3 haneli olur.
const int kDebugBoardRound = 175;

/// Yalnızca geliştirici yapıdaki tema seçici düğmesi (gu, zemin çubuğunun sağı).
const double kDebugPickerX = 386;
const double kDebugPickerY = 669;
const double kDebugPickerSize = 36;

// --- Efekt havuzları (PRD 7.3) — her biri ayrı, doluysa en eskisi yeniden kullanılır

/// Yalnızca kıvılcım parçacıkları.
const int kParticlePool = 64;

/// Yok olma (madeni para dönüşü) animasyonları: tahtadaki en fazla hedef.
const int kBreakAnimPool = kCols * kPlayableRows;

/// Halka/yıldız toplama ve oyun sonu şok halkası "pop" animasyonları.
const int kPopAnimPool = 16;

/// Yıldız "+3" yazıları.
const int kFloatTextPool = 8;

/// Hızlanmada (karede ≤32 adım) olay yağmuruna karşı karede yeni üretim sınırı.
const int kMaxSparksPerFrame = 24;
const int kMaxAnimsPerFrame = 12;

/// Görsel rastgelelik tohumu (oyun tohumunu tüketmez, PRD 7.2.1).
const int kVisualRandomSeed = 0x0B1026;

// --- Animasyonlar (PRD 7.2, 7.2.1, 5.11) -------------------------------------

/// Vuruş: hedef ölçeği 1 → 1.12 → 1.
const double kHitPulseSec = 0.10;
const double kHitPulseScale = 1.12;

/// Yok olma: 0.7 sn; ölçek Y = |cos(1.5·π·u)|, X = 1 + 0.1·sin(π·u),
/// dönme −0.6·u rad, yerçekimi 600 gu/sn², yatay ±35 gu/sn; u ≥ 0.5'te solar.
const double kBreakAnimSec = 0.7;
const double kBreakFlipTurns = 1.5;
const double kBreakWobbleX = 0.1;
const double kBreakRotation = -0.6;
const double kBreakGravity = 600;
const double kBreakDriftSpeed = 35;
const double kBreakFadeStart = 0.5;

/// Halka/yıldız toplama: 1.0 → 1.6 büyüyüp solma, 0.25 sn.
const double kPopSec = 0.25;
const double kPopScale = 1.6;

/// Oyun sonu şok halkası: süre ve büyüme.
const double kShockSec = 0.45;
const double kShockScale = 2.2;
const double kShockStroke = 3;

/// Kıvılcım: boyut 3, hız 120 → 0 gu/sn, ömür 0.35 sn (PRD 7.2 halka satırı).
const double kSparkSize = 3;
const double kSparkSpeed = 120;
const double kSparkLife = 0.35;

/// "+3" yazısı: 0.6 sn yukarı süzülür. Boy 20'den %40 büyütüldü (okunurluk);
/// koyu ince kenarlık ve hafif gölgeyle.
const double kFloatTextSec = 0.6;
const double kFloatTextRise = 30;
const double kFloatTextSize = 28;
const double kFloatTextOutline = 1.5;
const double kFloatTextOutlineAlpha = 0.85;
const double kFloatTextShadowBlur = 3;

/// Yıldız nabzı: 0.95–1.05, 1.2 sn.
const double kStarPulseSec = 1.2;
const double kStarPulseMin = 0.95;
const double kStarPulseMax = 1.05;

/// Tehlike uyarısı: 7. satırda hedef varken zemin kenarı nefes alır (1.2 sn döngü).
const double kDangerPulseSec = 1.2;
const double kDangerGlowHeight = 6;

/// Satır ilerleme: zemin çubuğu kenarında ışık süpürmesi.
const double kAdvanceSweepSec = 0.3;
const double kAdvanceSweepWidth = 80;

/// Skor nabzı (satır ilerlemede).
const double kScorePulseSec = 0.2;
const double kScorePulseScale = 1.15;

// --- Ses (PRD 8) — sınırlar duvar saatiyle çalışır, simülasyon adımıyla değil

const int kSfxMinGapMs = 50;
const int kSfxMaxConcurrent = 8;
const double kMusicVolume = 0.35;

/// Üst üste binen efektlerde kırpılmaya karşı marj (−3 dBFS tepeli dosyalar).
const double kSfxVolume = 0.8;

/// SFX başına önceden açılan oynatıcı sayısı (AudioPool).
const int kSfxPoolPlayers = 4;

/// Vuruş sesi varyant sayısı; simülasyondan bağımsız bir sayaçla sırayla döner (8.1).
const int kHitVariants = 3;

/// Uçuş sesi (vuruş, duvar) çalmaya başladıktan sonra süresi + bu pay boyunca
/// takip edilir; uçuş bu sürede biterse durdurulur. Takipte sayı sınırı yok.
const int kSfxFlightStopMarginMs = 50;

/// Geri basınç (platform iş parçacığı kuyruğu birikmesin; geç ses yerine
/// sessizlik): bir dosyanın en çok bu kadar başlatması aynı anda sürer; toplam
/// süren başlatma [kSfxMaxPendingStarts] ve üstündeyken önemsiz sesler
/// (vuruş, duvar, atış) atlanır.
const int kSfxMaxPendingPerFile = 1;
const int kSfxMaxPendingStarts = 3;

/// Kalabalık uçuş: havada bu kadar ve üstü top varken vuruş ve duvar sesi en az
/// [kSfxCrowdMinGapMs] aralıkla çalar (diğerleri [kSfxMinGapMs]).
const int kSfxCrowdBalls = 24;
const int kSfxCrowdMinGapMs = 100;

// --- Orbitfall arka planı ----------------------------------------------------

/// Kayan yıldız tozu: iki parallaks katman.
const int kStarDustPerLayer = 30;
const double kStarDustSpeedFar = 5;
const double kStarDustSpeedNear = 12;
const double kStarDustSizeFar = 1.2;
const double kStarDustSizeNear = 2;
const double kStarDustAlphaFar = 0.35;
const double kStarDustAlphaNear = 0.6;

// --- Orbitfall çizimi --------------------------------------------------------

/// Hedefin iç halka vurgusu.
const double kTargetRimStroke = 2;
const double kTargetRimInset = 4;
const double kTargetRimAlpha = 0.22;

/// Rakam gölgesi (PRD 7.1 "hafif gölge"): bulanıksız, [kNumberShadowOffset]
/// kadar aşağıda yarı saydam koyu kopya. Bulanıklık Impeller'da (J8, OpenGLES)
/// 56 rakamda ~110 ms raster tutuyordu (M3p ölçümü); 0 = bulanıklık yok.
const double kNumberShadowBlur = 0;
const double kNumberShadowOffset = 1;
const double kNumberShadowAlpha = 0.45;

/// HUD/zemin çubuğu kenarı: ince açık çizgi ve ortasında tema vurgusu (gu).
const double kHudEdgeStroke = 1.5;
const double kHudAccentWidth = 96;
const double kHudAccentStroke = 2.5;
const double kHudAccentGlowBlur = 3;

/// Zemin neonu atış noktasını izler: ilk inen topun x'ine ease-out kayma süresi
/// ve tuval kenarından bırakılan pay (segment hiç taşmaz).
const int kFloorAccentSlideMs = 200;
const double kFloorAccentEdgeMargin = 4;

/// Tehlike ve süpürme parlaklıkları.
const double kDangerGlowAlpha = 0.8;
const double kSweepAlpha = 0.8;
const double kSweepHeight = 4;

// --- Candy Burst arka planı --------------------------------------------------

/// Uzak katman: çapraz şeker şeritleri. Desen dikeyde kendini tekrar etsin diye
/// periyot = kVirtualH / [kCandyStripeCount] (45° şerit tuval boyunda tam
/// periyot sayısı kayar, ek yeri görünmez).
const int kCandyStripeCount = 19;
const double kCandyStripeWidth = 12;
const double kCandyStripeAlpha = 0.05;
const double kCandyStripeSpeed = 3;

/// Yakın katman: konfeti renklerinde serpinti çubukları.
const int kCandySprinkleCount = 36;
const double kCandySprinkleLength = 7;
const double kCandySprinkleWidth = 2.4;
const double kCandySprinkleAlpha = 0.35;
const double kCandySprinkleSpeed = 9;

// --- Candy Burst çizimi ------------------------------------------------------

/// Şeker hedefin sol üstteki parlak vurgusu (elips merkezi ve yarıçapları);
/// rakamın altına girmesin diye kenara yakın.
const double kCandyGlossX = -11;
const double kCandyGlossY = -13;
const double kCandyGlossRadiusX = 6;
const double kCandyGlossRadiusY = 3.5;
const double kCandyGlossAlpha = 0.35;

/// Hedefin dış bandındaki ince spiral (rakam bölgesinin dışında).
const double kCandySwirlInnerRadius = 15;
const double kCandySwirlOuterRadius = 21;
const double kCandySwirlTurns = 1.25;
const int kCandySwirlSegments = 40;
const double kCandySwirlStroke = 1.5;
const double kCandySwirlAlpha = 0.15;

/// Hedefin ince iç kenarı.
const double kCandyRimAlpha = 0.18;

/// Sedefli top: ince leylak kenar ve küçük parlak nokta.
const double kCandyBallRimStroke = 1.2;
const double kCandyBallRimAlpha = 0.6;
const double kCandyBallGlossOffset = -3.5;
const double kCandyBallGlossRadius = 3;

/// Sakız halkasının içindeki ince şeftali çizgi.
const double kCandyRingInnerStroke = 1.5;
const double kCandyRingInnerInset = 3.5;

/// Şeker yıldızın beyaz kenarı ve parlak noktası.
const double kCandyStarEdgeStroke = 1.6;
const double kCandyStarEdgeAlpha = 0.7;
const double kCandyStarGlossX = -3;
const double kCandyStarGlossY = -5;
const double kCandyStarGlossRadius = 2.5;

/// Serpinti biçimli kıvılcım: hız yönünde kısa, yuvarlak uçlu çubuk.
const double kCandySparkLength = 6;
const double kCandySparkWidth = 2.2;

// --- Pixel Drop çizimi -------------------------------------------------------

/// Piksel ızgarası (gu). Hedef, top, halka, yıldız, kıvılcım ve arka plan
/// blokları bu ızgaraya oturur; ızgara çizgileri hedef merkezinden geçer.
/// Silüet yalnızca tamamı kTargetRadius içinde kalan hücrelerdir (görünüm
/// çarpışma dairesini aşmaz); 2 gu hücreyle hedef 24 hücre (48 gu) genişliğinde,
/// eksenlerde görünümle çarpışma arasındaki boşluk 1 gu.
const double kPixelCell = 2;

/// HP rakamı: 3×5 piksellik glif, hedef merkezine hizalı. 1–2 hanede rakam
/// pikseli [kPixelDigitPx] (yükseklik 25 gu = çapın %50'si), 3 hanede
/// [kPixelDigitPx3] (20 gu = %40). Rakam pikselleri hedef ızgarasından
/// bağımsızdır; haneler arası boşluk [kPixelDigitGap] / [kPixelDigitGap3].
const int kPixelGlyphCols = 3;
const int kPixelGlyphRows = 5;
const double kPixelDigitPx = 5;
const double kPixelDigitGap = 5;
const double kPixelDigitPx3 = 4;
const double kPixelDigitGap3 = 2;

/// Hedefin 1 hücrelik kenar halkası: HP rengi ile beyazın karışımı (beyaz
/// oranı). Koyu duraklar koyu zeminden en az 3:1 ayrışır (testli).
const double kPixelRimWhiteMix = 0.35;

/// Hedefin üst-sol parlak yayı: halkanın hemen içindeki hücreler, merkez
/// açısı bu aralıkta (derece; ekran koordinatı, y aşağı: 225° = sol üst).
/// Rakam köşelerine değmeyecek kadar yukarıda (testli).
const double kPixelGlossFromDeg = 225;
const double kPixelGlossToDeg = 260;
const double kPixelGlossAlpha = 0.4;

/// Topun parlak hücresi (sol üst köşesi, merkeze göre gu).
const double kPixelBallGlintX = -6;
const double kPixelBallGlintY = -8;

/// Halka: dış kenar kPickupRadius, kalınlık 2 hücre (4 gu; kPickupStroke'a yakın).
const int kPixelRingCells = 2;

/// Halka ve yıldızın adımlı iki kareli parıltısı (yalnız görsel): kare süresi
/// ve sönük karede parıltı saydamlığı.
const double kPixelBlinkSec = 0.5;
const double kPixelBlinkDimAlpha = 0.45;

/// Halkanın 1 hücrelik yarı saydam piksel halesi (bulanık parıltı yerine) ve
/// HUD vurgusunun üst/alt 1 hücrelik yarı saydam şeridi.
const double kPixelHaloAlpha = 0.35;

/// Pixel Drop sabit zemin resminin (degrade + tarama çizgisi) en yüksek
/// çözünürlüğü (piksel/gu): yumuşak içerik, bellek sınırı (~4.7 MB).
const double kPixelBackdropMaxPxPerGu = 2;

/// Tek drawRawAtlas çağrısındaki en çok sprite (56+ hedef × 6 parça).
const int kPixelAtlasBatchCapacity = 400;

/// Yıldızın parlak karede beyaz yanan hücresi (sol üst köşesi, merkeze göre gu).
const double kPixelStarGlintX = -4;
const double kPixelStarGlintY = -2;

/// Arka plan: sabit, çok soluk yatay tarama çizgileri (periyot, kalınlık gu).
const double kPixelScanlinePeriod = 4;
const double kPixelScanlineHeight = 2;
const double kPixelScanlineAlpha = 0.035;

/// Arka plan: yavaşça düşen seyrek piksel blokları (1–2 hücre kare). Kayma
/// hücre adımlarıyla yapılır (piksel hissi).
const int kPixelDropCount = 30;
const int kPixelDropMaxCells = 2;
const double kPixelDropAlpha = 0.22;
const double kPixelDropSpeed = 8;

// --- Abyss arka planı --------------------------------------------------------

/// Yavaşça yükselen halka kabarcıklar (bir kez kaydedilmiş Picture; karede
/// yalnızca kaydırma). Yarıçap aralığı, kalınlık ve saydamlık gu.
const int kAbyssBubbleCount = 24;
const double kAbyssBubbleMinRadius = 1.5;
const double kAbyssBubbleMaxRadius = 4;
const double kAbyssBubbleStroke = 1;
const double kAbyssBubbleAlpha = 0.2;
const double kAbyssBubbleSpeed = 9;

/// Çok yavaş aşağı inen plankton tozu ("deniz karı"; tek drawRawPoints).
const int kAbyssDustCount = 90;
const double kAbyssDustSize = 1.4;
const double kAbyssDustAlpha = 0.28;
const double kAbyssDustSpeed = 3;

// --- Abyss çizimi (denizanası hedef; orijin = hedef merkezi, gu) -------------

/// Kubbe: (0, [kAbyssBellCenterY]) merkezli yarım elips. Gövde kenarları
/// kubbenin iki ucundan etek çizgisine ([kAbyssHemY]) iner; alt köşeler
/// [kAbyssHemCornerRadius] yarıçapla yuvarlanır; etek [kAbyssHemWaves] dalga,
/// [kAbyssHemDepth] derinlik. Silüetin tamamı çarpışma dairesinin içindedir.
const double kAbyssBellCenterY = -6;
const double kAbyssBellRadiusX = 23;
const double kAbyssBellRadiusY = 17;
const double kAbyssHemY = 12;
const double kAbyssHemCornerRadius = 4;
const int kAbyssHemWaves = 4;
const double kAbyssHemDepth = 2;

/// Dokunaçlar: x konumları, üst/alt uç, S kıvrım genliği ve kalınlık.
const List<double> kAbyssTentacleXs = [-8, 0, 8];
const double kAbyssTentacleTop = 14;
const double kAbyssTentacleBottom = 21;
const double kAbyssTentacleAmp = 2;
const double kAbyssTentacleStroke = 2.5;

/// Gövdenin iç kenarındaki açık halka (biyolüminesan kenar): HP rengi ile
/// beyazın karışımı, gövdenin içine doğru [kAbyssRimStroke] kalınlık.
const double kAbyssRimStroke = 2;
const double kAbyssRimWhiteMix = 0.45;

/// Hale: HP renginde, bir kez bulanıklaştırılıp atlasa pişirilen yumuşak disk.
/// Çarpışma alanını sezdirir; dış sınırı komşu hücrelere değmez.
const double kAbyssHaloRadius = 22;
const double kAbyssHaloBlur = 3;
const double kAbyssHaloAlpha = 0.22;

/// Kubbedeki parlak vurgu (oval merkezi ve yarıçapları).
const double kAbyssGlossX = -7;
const double kAbyssGlossY = -15;
const double kAbyssGlossRadiusX = 5;
const double kAbyssGlossRadiusY = 2.5;
const double kAbyssGlossAlpha = 0.35;

/// HP rakamının kapladığı kutu (yarı genişlik, yarı yükseklik): Roboto Bold
/// metriği (rakam ~0.56 em, büyük harf ~0.71 em) + pay. Testler kutunun
/// gövdenin içinde kaldığını denetler.
const double kAbyssDigitBoxHalfW = 14;
const double kAbyssDigitBoxHalfH = 9;
const double kAbyssDigitBox3HalfW = 17;
const double kAbyssDigitBox3HalfH = 8;

/// Atılan top: dolu çekirdek + pişmiş yumuşak hale.
const double kAbyssBallCoreRadius = 10.5;
const double kAbyssBallHaloBlur = 2.5;
const double kAbyssBallHaloAlpha = 0.45;

/// Halka: iç "jöle zarı" çizgisi ve opaklık nabzı (yalnız görsel).
const double kAbyssRingInnerInset = 4;
const double kAbyssRingInnerStroke = 1.5;
const double kAbyssRingInnerAlpha = 0.45;
const double kAbyssRingPulseSec = 1.6;
const double kAbyssRingPulseMin = 0.85;

/// Deniz yıldızı: iç köşe oranı, yuvarlak kol ucu için kontrol noktası oranı
/// (kol ucu dış yarıçapa denk gelir) ve ortadaki açık nokta.
const double kAbyssStarInnerRatio = 0.42;
const double kAbyssStarControlRatio = 1.66;
const double kAbyssStarDotRadius = 2;
const double kAbyssStarDotAlpha = 0.7;

/// Kıvılcım: kabarcık (halka + parlak nokta); çapı kıvılcım boyunun katı.
const double kAbyssSparkBubbleRadius = 3;
const double kAbyssSparkBubbleStroke = 1;
const double kAbyssSparkScale = 1.6;

/// Tek drawRawAtlas çağrısındaki en çok sprite (63 hedef × 4 parça).
const int kAbyssAtlasBatchCapacity = 260;

// --- Ink & Paper arka planı --------------------------------------------------

/// Kâğıt zemini (degrade + gren + lif) bir kez tek resme pişirilir; en yüksek
/// çözünürlük (piksel/gu) bellek sınırıdır (J8 ~3.5 MB, en çok ~4.7 MB).
const double kInkBackdropMaxPxPerGu = 2;

/// Kâğıt greni: sabit tohumlu noktalar (yarısı koyu, yarısı açık).
const int kInkGrainCount = 2600;
const double kInkGrainSize = 0.8;
const double kInkGrainDarkAlpha = 0.06;
const double kInkGrainLightAlpha = 0.12;

/// Kâğıt lifleri: kısa, ince, hafif kavisli çizgiler.
const int kInkFiberCount = 140;
const double kInkFiberMinLength = 6;
const double kInkFiberMaxLength = 22;
const double kInkFiberBend = 3;
const double kInkFiberStroke = 0.5;
const double kInkFiberAlpha = 0.07;

/// Çok yavaş kayan soluk mürekkep lekeleri (wash): bulanık daire kümesi tek
/// sprite'ta, düşük çözünürlüklü ayrı bir atlasta (yumuşak içerik); karede
/// tek drawRawAtlas. Leke başına [kInkWashBlobs] daire, merkezden en çok
/// [kInkWashSpread] gu.
const int kInkWashCount = 6;
const int kInkWashBlobs = 4;
const double kInkWashRadius = 34;
const double kInkWashSpread = 22;
const double kInkWashBlur = 12;
const double kInkWashAlphaMin = 0.05;
const double kInkWashAlphaMax = 0.09;
const double kInkWashMinScale = 1;
const double kInkWashMaxScale = 1.8;
const double kInkWashSpeedX = 2.5;
const double kInkWashSpeedY = 1.2;
const double kInkWashMaxPxPerGu = 0.75;

/// Leke dairelerinin en küçük yarıçapı (kInkWashRadius oranı).
const double kInkWashBlobMinRatio = 0.6;

// --- Ink & Paper çizimi (orijin = nesne merkezi, gu) ---------------------------

/// Hedef gövdesi: düzensiz fırça disk, R(θ) = [kInkBodyRadius] + [kInkBodyWobble]
/// × Σ ağırlık·sin(k·θ + faz); ağırlıklar toplamı 1 → R ≤ 22.7 < kTargetRadius.
/// Fazlar varyant başına sabit tohumdan. Varyant sütuna göre seçilir.
const double kInkBodyRadius = 21.5;
const double kInkBodyWobble = 1.2;
const List<int> kInkBodyHarmonics = [3, 5, 7];
const List<double> kInkBodyHarmonicWeights = [0.5, 0.3, 0.2];
const int kInkBodySegments = 72;
const int kInkTargetVariants = 3;
const int kInkGeometrySeed = kVisualRandomSeed + 0x1A4;

/// Enso kenarı: gövdenin içinde, başta bastırılıp ([kInkRimHeadFraction]
/// boyunca kalınlaşan) sonra incelen fırça halkası; [kInkRimGapDeg] açıklık.
/// Renk: HP rengi ile sumi (top rengi) karışımı.
const double kInkRimMinStroke = 1.5;
const double kInkRimMaxStroke = 3.5;
const double kInkRimInset = 0.3;
const double kInkRimGapDeg = 28;
const double kInkRimHeadFraction = 0.08;
const List<double> kInkRimStartDeg = [-110, 10, 130];
const double kInkRimDarkMix = 0.45;

/// Mürekkep yayılması (nijimi): HP renginde, bir kez bulanıklaştırılmış disk;
/// görünür sınır (r + 2σ) komşu hücreye değmez.
const double kInkBleedRadius = 22;
const double kInkBleedBlur = 2.5;
const double kInkBleedAlpha = 0.2;

/// Kuru fırça dokusu: gövdeye kırpılmış eş merkezli kısa yaylar; sumi
/// renginde düşük saydamlıkla basılır (yalnızca koyulaştırır).
const int kInkStreakCount = 9;
const double kInkStreakMinRadius = 12;
const double kInkStreakMaxRadius = 20;
const double kInkStreakMinSweepDeg = 20;
const double kInkStreakMaxSweepDeg = 60;
const double kInkStreakStroke = 0.8;
const double kInkStreakAlpha = 0.14;

/// HP rakamının kapladığı kutu (Roboto Bold metriği, Abyss ile aynı değerler).
const double kInkDigitBoxHalfW = 14;
const double kInkDigitBoxHalfH = 9;
const double kInkDigitBox3HalfW = 17;
const double kInkDigitBox3HalfH = 8;

/// Atılan top: sumi damlası + sol üstte parlama.
const double kInkBallRadius = 12.5;
const double kInkBallGlintX = -4;
const double kInkBallGlintY = -4.5;
const double kInkBallGlintRadiusX = 3;
const double kInkBallGlintRadiusY = 2;
const double kInkBallGlintAlpha = 0.55;

/// Halka: dış yarıçap kPickupRadius, başta bastırılıp incelen fırça halka;
/// uçlar [kInkRingOverlapDeg] üst üste biner. İçi boştur. Ortak pişmiş
/// parıltı kâğıtta pigment yayılması gibi [kInkRingGlowAlpha] ile basılır.
const double kInkRingMinStroke = 3.5;
const double kInkRingMaxStroke = 5.5;
const double kInkRingOverlapDeg = 20;
const double kInkRingStartDeg = -100;
const double kInkRingHeadFraction = 0.06;
const int kInkRingSegments = 96;
const double kInkRingGlowAlpha = 0.45;

/// Altın yaprak yıldız: koyu ince kenar ve açık altın yaprak lekecikleri
/// (x, y, yarıçap üçlüleri).
const double kInkStarEdgeStroke = 1.3;
const List<double> kInkStarFlecks = [-3, -4, 1.6, 4, 1, 1.2, -1, 5, 1];
const double kInkStarFleckLightMix = 0.5;

/// Mürekkep damlası kıvılcım: hız yönünde uzamış oval + uydu damlacıklar
/// (varyant başına x, y, yarıçap üçlüleri; birim = damla yarıçapı). Görünen
/// boy = kıvılcım boyu × [kInkSparkScale].
const double kInkDropRadius = 2.2;
const double kInkDropStretch = 1.8;
const double kInkDropExtent = 3.6;
const List<List<double>> kInkDropSatellites = [
  [-2.6, 0.6, 0.45],
  [-2.4, -0.7, 0.4, -3.2, 0.4, 0.28],
  [2.7, 0, 0.35, -2.5, -0.5, 0.38],
];
const double kInkSparkScale = 1.6;

/// HUD: top simgesinin arkasındaki kâğıt diski (simgeden bu kadar büyük).
const double kInkHudIconBacking = 1.5;

/// Satır süpürmesi: kâğıt kenarında incelen kuru fırça darbesi (zemin
/// kenarının hemen üstünde); [kInkSweepDryLines] ince kuru fırça boşluğu.
const double kInkSweepHeight = 5;
const int kInkSweepDryLines = 3;
const double kInkSweepDryStroke = 0.6;
const double kInkSweepDryAlpha = 0.6;
const double kInkSweepTailTaper = 0.3;

/// Tehlike nefesi: zemin kenarından yukarı solan mürekkep sızıntısı.
const double kInkSeepHeight = 14;
const int kInkSeepBlobs = 7;
const double kInkSeepBlobRadius = 9;
const double kInkSeepBlur = 4;
const double kInkSeepAlpha = 0.8;

/// Tek drawRawAtlas çağrısındaki en çok sprite (63 hedef × 4 parça).
const int kInkAtlasBatchCapacity = 260;
