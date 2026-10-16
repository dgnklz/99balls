# ASSUMPTIONS.md

Bu dosya, PRD'de (docs/PRD.md) belirsiz kalan ya da PRD ile referans projeler
çeliştiğinde alınan kararların kaydıdır. Yapay zeka her kararı buraya yazar.

## 1. Referans projeler (yalnızca okunur, kopyalanmaz)

Konum: C:\Users\Dogan\Desktop\MobileProject\SudokuPure V2

Bu klasörde Sudoku Pure'un 3 projesi vardır: standart, premium ve iOS'a
özelleştirilmiş sürüm. PRD'nin istediği altyapı özellikleri bu projelerde
mevcuttur. Yapay zeka bu projeleri okuyup yapıyı öğrenir, kodu yeni
projenin mimarisine (Riverpod, go_router, gen-l10n) uyarlayarak yeniden yazar.

Kural: Firestore şeması ve EmailJS şablon alanları için bu projeler geçerlidir.
Diğer her konuda docs/PRD.md geçerlidir.

### Özellik -> aranacak yer (yapay zeka doldurur)

| Özellik | PRD bölümü | Referans projede dosya/klasör | Not |
| --- | --- | --- | --- |
| EmailJS geri bildirim ekranı ve istek gövdesi | 9.8 | (doldurulacak) | |
| Dil seçim penceresi (popup) | 9.7 | (doldurulacak) | |
| Ayarlar ekranı | 9.7 | (doldurulacak) | |
| Google ile giriş | 11.1 | (doldurulacak) | |
| Apple ile giriş (iOS) | 11.1 | (doldurulacak) | iOS projesine bak |
| Firestore skor tablosu şeması ve sorgusu | 11.6 | (doldurulacak) | |
| banned listesi ve filtreleme | 11.7 | (doldurulacak) | |
| Hesap silme | 11.1 | (doldurulacak) | |

Üç proje arasında fark varsa (standart / premium / iOS) iOS'a özgü olanı
yalnızca iOS kodunda kullan; ortak olanı baz al.

## 2. PRD'den gelen varsayımlar

PRD Bölüm 1'deki V1–V8 varsayımları geçerlidir. Burada tekrar edilmez.
Bir varsayım değiştirilirse buraya tarih ve gerekçe ile yazılır.

## 3. Uygulama sırasında alınan kararlar

Her karar için bir satır ekle. Karar PRD'ye aykırı olamaz; yalnızca boşluğu doldurur.

| Tarih | PRD bölümü | Belirsizlik | Alınan karar | Gerekçe |
| --- | --- | --- | --- | --- |
| 2026-10-16 | 2.2, 13 | 2.2 `lib/game_core/` klasörü diyor, 13 ayrı paket (`game_core/lib/src/constants.dart`) diyor | `lib/game_core/` klasörü kullanılır, ayrı paket yapılmaz | CLAUDE.md "Bölüm 2'deki klasör yapısına birebir uy" diyor. Saflığı `no_flutter_in_core_test` korur (game_core dışından `package:` importu da yasak) |
| 2026-10-16 | 2.4, 13 | Sabitler 2.4'te `core/config/game_config.dart`, 13'te iki ayrı dosyada | game_core sabitleri `lib/game_core/constants.dart` içinde (Geometri, Simülasyon, Girdi grupları + `kStartBalls`, `kPercentBound`, `kRowTargetCounts`). Sunum/UI/ses sabitleri M2'de `core/config/game_config.dart` içinde olacak | game_core dışarıya bağımlı olamaz |
| 2026-10-16 | 14.1 | `row_generation_test` golden'ı için T dizisi tanımlı değil | Tohum 20261015; 0. satır ilk tahta (T=1), i. satır `nextRow(i+1)`. Dosya: `test/game_core/golden/rows_seed_20261015.json`, `UPDATE_GOLDEN=1` ile yeniden üretilir | T oyuna bağlı; artan T farklı HP aralıklarını kapsar. Golden, PRD 6.1–6.3 baştan yazılan bağımsız bir Python uygulamasıyla birebir doğrulandı |
| 2026-10-16 | 6.1 | "soldan sağa" çarpan sırası | Top sütunları artan sütun numarasına sıralanır, m2 bu sırayla çekilir | Metnin doğrudan okuması |
| 2026-10-16 | 4.2, 13 | `kPitch` = 59.43 mi, 416/7 = 59.4286 mı | 59.43 (Bölüm 13'teki değer) | Adlandırılmış sabit tablosu esas alındı |
| 2026-10-16 | 6.3 | SplitMix64 web'de çalışmaz (JS'de int 64-bit değil) | Kabul edildi, hedef yalnızca Android/iOS | PRD "native Dart" diyor |
| 2026-10-16 | 2.1 | "Flame'e dokunma" talimatı ile 2.1 bağımlılık listesi | `flame` ve `flame_audio` pubspec'e eklendi, Flame kodu yazılmadı | 2.1 bağımlılıkları M1 kapsamında |
| 2026-10-16 | 2.5 | gen-l10n `generate: true` ve asset bildirimi | M1'de eklenmedi; .arb ve asset dosyalarıyla birlikte M3/M4'te eklenecek | Dosyalar olmadan anlamsız ya da derleme hatası |
| 2026-10-16 | 6.3, 5.11 | splitmix64 tablosu ve yıldız şansı 0 iken RNG tüketimi | PRD düzeltildi (14.1 ve 5.11), karar gerekmez | — |

## 4. Kullanıcıya sorulacaklar

Cevabı beklenen sorular (yapay zeka işe devam eder, cevap gelince karar tablosunu günceller):

- [ ] Uygulama adı ve logo yönü
- [ ] Paket kimliği (bundle id) ve Firebase projesi
- [ ] Gizlilik politikası adresi (kPrivacyUrl)
- [ ] 9.7 gizlilik bağlantısını "harici tarayıcıda açmak" için `url_launcher` gerekir ama 2.1 tablosunda yok. M4'te eklensin mi?