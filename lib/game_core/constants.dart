/// game_core sabitleri (PRD Bölüm 13). Pure Dart; flutter importu yasaktır.
///
/// "Simülasyon" grubundaki bir değer değişirse doğrulama tabloları ve
/// altın kayıt dosyaları (test/game_core/golden) yeniden üretilmelidir.
library;

// --- Geometri (gu) ---------------------------------------------------------

/// Sanal tuval genişliği.
const double kVirtualW = 416;

/// Sanal tuval yüksekliği.
const double kVirtualH = 703;

// --- Izgara ----------------------------------------------------------------

/// Sütun sayısı.
const int kCols = 7;

/// Hücre aralığı (kare hücre, yatay ve dikey).
const double kPitch = 59.43;

/// 0. satırın merkez y değeri.
const double kRow0CenterY = 135.7;

/// Oynanabilir satır sayısı (0..7). Bu indekse inen sayılı top oyunu bitirir.
const int kPlayableRows = 8;

/// Oyun bitiş satırı (r = 8).
const int kGameOverRow = kPlayableRows;

/// Tahtanın mantıksal satır sayısı: 0..kGameOverRow.
const int kBoardRows = kGameOverRow + 1;

// --- Sınırlar --------------------------------------------------------------

/// Tavan (HUD çubuğunun alt kenarı).
const double kCeilingY = 53;

/// Zemin çizgisi (zemin çubuğunun üst kenarı).
const double kFloorY = 635;

/// Atılan topun yarıçapı.
const double kBallRadius = 13;

/// Fırlatma yüksekliği: zemindeki topun merkez y değeri.
const double kLaunchY = kFloorY - kBallRadius;

/// Sol ve sağ duvar (ekran kenarları).
const double kLeftWallX = 0;
const double kRightWallX = kVirtualW;

/// Top merkezinin duvar/tavan sınırları (yarıçap hesaba katılmış).
const double kBallMinX = kLeftWallX + kBallRadius;
const double kBallMaxX = kRightWallX - kBallRadius;
const double kBallMinY = kCeilingY + kBallRadius;

/// İlk atışın fırlatma x'i (tuval ortası).
const double kLaunchStartX = kVirtualW / 2;

/// Fırlatma x'inin sıkıştırıldığı aralık: [kLaunchMinX, kLaunchMaxX].
const double kLaunchMinX = kBallMinX;
const double kLaunchMaxX = kBallMaxX;

// --- Nesneler ----------------------------------------------------------------

/// Sayılı top (hedef) yarıçapı.
const double kTargetRadius = 25;

/// Toplanabilir halka ve yıldız yarıçapı.
const double kPickupRadius = 18;

/// Top–hedef temas mesafesi (38).
const double kHitDistance = kBallRadius + kTargetRadius;

/// Top–halka/yıldız toplama mesafesi (31).
const double kPickupDistance = kBallRadius + kPickupRadius;

// --- Hareket ve zaman --------------------------------------------------------

/// Top hızı (gu/sn).
const double kBallSpeed = 585;

/// Sabit simülasyon adımı sayısı (adım/sn).
const int kStepsPerSec = 120;

/// Ardışık iki topun fırlatılması arasındaki adım sayısı.
const int kLaunchIntervalSteps = 17;

/// Uçuş zaman aşımı (sn).
const int kFlightTimeoutSec = 20;

/// Uçuş zaman aşımı (adım).
const int kFlightTimeoutSteps = kFlightTimeoutSec * kStepsPerSec;

/// Topun bir adımda aldığı yol (4.875 gu).
const double kBallStepDistance = kBallSpeed / kStepsPerSec;

/// Bir adımda en fazla kaç çarpışma işlenir (tünelleme koruması).
const int kSweepMaxIterations = 4;

/// Toplama süresi (sn) ve çekirdekteki karşılığı (adım, yuvarlanmış: 30).
const double kCollectSec = 0.25;
const int kCollectSteps = 30;

/// Satır kayma süresi (sn) ve çekirdekteki karşılığı (adım, yukarı: 21.6 → 22).
const double kAdvanceSec = 0.18;
const int kAdvanceSteps = 22;

// --- Top sayısı --------------------------------------------------------------

/// Oyun başlangıcındaki top sayısı.
const int kStartBalls = 1;

/// Top sayısı üst sınırı.
const int kMaxBalls = 99;

// --- Girdi -------------------------------------------------------------------

/// Sürükleme ölü bölgesi (gu).
const double kAimDeadZone = 10;

/// Yataydan en küçük nişan açısı (derece).
const double kMinAimAngleDeg = 5;

/// [kMinAimAngleDeg]'in sinüs ve kosinüsü. Çekirdekte trig yasak olduğu için
/// literal yazılır; aim_test bunları dart:math ile doğrular.
const double kMinAimSin = 0.08715574274765817;
const double kMinAimCos = 0.9961946980917455;

/// Atış yönü tamsayıya çevrilirken kullanılan çarpan: shot = round(a × 100).
const int kShotScale = 100;

// --- Satır üretimi (PRD Bölüm 6) ---------------------------------------------

/// Yüzde çekimlerinin üst sınırı: `nextInt(kPercentBound)` 0..99 verir.
const int kPercentBound = 100;

/// Bir satırdaki sayılı top sayısı seçenekleri; [kBallCountWeights] ile eşleşir.
const List<int> kRowTargetCounts = [2, 3, 4, 5];

/// [kRowTargetCounts] ağırlıkları (yüzde, toplamı [kPercentBound]).
const List<int> kBallCountWeights = [24, 29, 29, 18];

/// Satıra halka konma olasılığı (yüzde).
const int kRingChancePct = 56;

/// Çarpanın iki katı: m2 ∈ {2, 3, 4} → çarpan ×1, ×1.5, ×2.
const List<int> kMultipliersM2 = [2, 3, 4];

// --- Yıldız (PRD Bölüm 5.11) -------------------------------------------------

/// Satıra yıldız konma olasılığı (yüzde).
const int kStarChancePct = 25;

/// Yıldız başına skor puanı.
const int kStarScore = 3;

// --- Tekrar oynatma (PRD Bölüm 11.8) -----------------------------------------

/// Makul skor üst sınırı.
const int kMaxPlausibleScore = 2000;

/// Kodlanmış (base64) tekrar kaydının en büyük uzunluğu.
const int kReplayMaxBytes = 20480;

/// Tekrar kaydı biçim sürümü.
const int kReplayFormatVersion = 1;
