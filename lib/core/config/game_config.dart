/// Sunum, girdi ve arayüz sabitleri (PRD Bölüm 2.4, 4, 5.2, 7, 13).
///
/// Simülasyon sabitleri `lib/game_core/constants.dart` içindedir; tüm
/// koordinatlar 416×703 gu sanal tuvalindedir.
library;

// --- Kare döngüsü (PRD 2.3, 10.2) --------------------------------------------

/// Bir karede işlenecek en fazla simülasyon adımı; fazlası atılır.
const int kMaxStepsPerFrame = 8;

/// İlk karede (ve arka plandan dönüşte) kabul edilen en büyük dt (sn).
const double kFirstFrameMaxDt = 1 / 30;

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

// --- Nesne çizimi (PRD 4.3, 5.11, 7.1) ---------------------------------------

/// Atılan topun çizgi kalınlığı.
const double kBallStroke = 4.5;

/// Toplanabilir halkanın çizgi kalınlığı ve parlama bulanıklığı.
const double kPickupStroke = 5;
const double kPickupGlowBlur = 4;

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
