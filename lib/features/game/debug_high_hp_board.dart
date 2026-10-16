import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../../game_core/model/board.dart';
import '../../game_core/model/cell.dart';
import '../../game_core/model/pickup.dart';
import '../../game_core/rules/round_state_machine.dart';

/// YALNIZCA GELİŞTİRİCİ: yüksek HP tahtası (debug ve profile yapı).
/// Amaç: 100+ HP ve c10 hedeflerini her temada hemen görmek, profilde ağır
/// tahtayı izlemek. Her HP durağının sınır değerleri (PRD 7.1), üç haneliler
/// ve 99 tahtadadır. 0–5. satırlar dolu, 6–7 boş (hemen tehlike/oyun sonu yok).
const TargetCell _hp1 = TargetCell(1);
const TargetCell _hp2 = TargetCell(2);
const TargetCell _hp3 = TargetCell(3);
const TargetCell _hp4 = TargetCell(4);
const TargetCell _hp6 = TargetCell(6);
const TargetCell _hp7 = TargetCell(7);
const TargetCell _hp9 = TargetCell(9);
const TargetCell _hp13 = TargetCell(13);
const TargetCell _hp17 = TargetCell(17);
const TargetCell _hp24 = TargetCell(24);
const TargetCell _hp26 = TargetCell(26);
const TargetCell _hp27 = TargetCell(27);
const TargetCell _hp32 = TargetCell(32);
const TargetCell _hp34 = TargetCell(34);
const TargetCell _hp36 = TargetCell(36);
const TargetCell _hp40 = TargetCell(40);
const TargetCell _hp44 = TargetCell(44);
const TargetCell _hp46 = TargetCell(46);
const TargetCell _hp48 = TargetCell(48);
const TargetCell _hp49 = TargetCell(49);
const TargetCell _hp50 = TargetCell(50);
const TargetCell _hp99 = TargetCell(99);
const TargetCell _hp100 = TargetCell(100);
const TargetCell _hp111 = TargetCell(111);
const TargetCell _hp120 = TargetCell(120);
const TargetCell _hp148 = TargetCell(148);
const TargetCell _hp168 = TargetCell(168);
const TargetCell _hp188 = TargetCell(188);
const TargetCell _hp198 = TargetCell(198);
const PickupCell _ring = PickupCell(PickupKind.ring);
const PickupCell _star = PickupCell(PickupKind.star);

/// Satır × sütun (0 = üst satır). Boş hücre null. Satır başına en çok 5 hedef
/// ve 1 toplanabilir: gerçek satır üretimiyle aynı sınır.
const List<List<Cell?>> kDebugHighHpRows = [
  [_hp198, _hp188, null, _hp148, _ring, _hp111, _hp100],
  [_hp99, _hp50, _hp48, null, _hp44, _star, _hp36],
  [_hp34, null, _hp32, _hp27, _hp26, _hp24, null],
  [_hp17, _hp13, _ring, _hp7, null, _hp6, _hp3],
  [_hp2, null, _hp40, _hp1, null, _hp46, _hp168],
  [null, _hp4, null, _hp120, _hp9, null, _hp49],
];

/// Tabloyu yeni bir tahtaya yazar; kalan satırlar boş kalır.
Board buildDebugHighHpBoard() {
  final board = Board();
  for (var row = 0; row < kDebugHighHpRows.length; row++) {
    final cells = kDebugHighHpRows[row];
    for (var col = 0; col < kCols; col++) {
      board.setCell(row, col, cells[col]);
    }
  }
  return board;
}

/// Hazır tahtayla oturum: 99 top (sonraki satırlar hpFor(99, m2) = 99/148/198),
/// tur [kDebugBoardRound]. game_core'un mevcut [GameSession.forTest] kurucusu
/// kullanılır; çekirdek değişmez.
GameSession debugHighHpSession(int seed) => GameSession.forTest(
      board: buildDebugHighHpBoard(),
      seed: seed,
      initialBallCount: kMaxBalls,
      initialRound: kDebugBoardRound,
    );
