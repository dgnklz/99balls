import '../constants.dart';
import '../rules/row_generator.dart';
import 'cell.dart';

/// Mantıksal ızgara: [kBoardRows] satır (0..kGameOverRow) × [kCols] sütun.
class Board {
  final List<Cell?> _cells = List<Cell?>.filled(kBoardRows * kCols, null);

  static double centerX(int col) => kPitch * col + kPitch / 2;
  static double centerY(int row) => kRow0CenterY + kPitch * row;

  Cell? cellAt(int row, int col) => _cells[row * kCols + col];

  void setCell(int row, int col, Cell? cell) => _cells[row * kCols + col] = cell;

  /// Tüm satırları bir aşağı kaydırır; 0. satır boşalır. Son satırdaki
  /// içerik atılır (oyun o satırda bitmiş ya da nesneler silinmiş olmalıdır).
  void shiftDown() {
    for (var row = kBoardRows - 1; row > 0; row--) {
      for (var col = 0; col < kCols; col++) {
        setCell(row, col, cellAt(row - 1, col));
      }
    }
    for (var col = 0; col < kCols; col++) {
      setCell(0, col, null);
    }
  }

  /// Üretilen satırı 0. satıra koyar.
  void insertRow(GeneratedRow row) {
    for (var col = 0; col < kCols; col++) {
      setCell(0, col, row.cells[col]);
    }
  }

  /// Hedefin HP'sini 1 azaltır ve kalan HP'yi döndürür. 0 olan hedef silinir.
  int hitTarget(int row, int col) {
    final cell = cellAt(row, col);
    if (cell is! TargetCell) {
      throw StateError('no target at ($row, $col)');
    }
    final hpLeft = cell.hp - 1;
    setCell(row, col, hpLeft > 0 ? TargetCell(hpLeft) : null);
    return hpLeft;
  }

  bool hasTargetInRow(int row) {
    for (var col = 0; col < kCols; col++) {
      if (cellAt(row, col) is TargetCell) return true;
    }
    return false;
  }
}
