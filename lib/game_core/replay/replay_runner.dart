import '../constants.dart';
import '../engine/aim.dart';
import '../rules/round_state_machine.dart';
import 'shot_log.dart';

/// Tekrar kaydının reddedilme nedeni.
enum ReplayRejection {
  tooLarge,
  malformed,
  noShots,
  implausibleScore,
  shotIntervalTooShort,
  invalidShot,
  shotNotReady,
  notFinished,
  scoreMismatch,
}

class ReplayVerdict {
  /// null ise kayıt geçerlidir.
  final ReplayRejection? rejection;

  /// Başsız oynatmanın ürettiği skor (oynatma yapıldıysa).
  final int? replayedScore;

  const ReplayVerdict._(this.rejection, this.replayedScore);

  const ReplayVerdict.rejected(ReplayRejection reason, {int? replayedScore})
      : this._(reason, replayedScore);

  const ReplayVerdict.valid(int score) : this._(null, score);

  bool get isValid => rejection == null;

  @override
  String toString() => isValid ? 'ReplayVerdict.valid($replayedScore)' : 'ReplayVerdict.rejected($rejection)';
}

/// Kaydı aynı tohumla başsız oynatır ve bildirilen skoru doğrular (PRD 11.8).
///
/// Geçerli bir kayıt: en az 1 atış, skor 0..[kMaxPlausibleScore], atış
/// aralıkları ≥ [kLaunchIntervalSteps], her atış adımında oyun ready ve yön
/// geçerli, son atıştan sonra oyun gameOver ile biter ve skor eşittir.
ReplayVerdict verifyReplay({
  required int seed,
  required String encoded,
  required int claimedScore,
}) {
  if (encoded.length > kReplayMaxBytes) {
    return const ReplayVerdict.rejected(ReplayRejection.tooLarge);
  }
  final List<ShotRecord> shots;
  try {
    shots = decodeShots(encoded);
  } on ReplayFormatException {
    return const ReplayVerdict.rejected(ReplayRejection.malformed);
  }
  if (shots.isEmpty) {
    return const ReplayVerdict.rejected(ReplayRejection.noShots);
  }
  if (claimedScore < 0 || claimedScore > kMaxPlausibleScore) {
    return const ReplayVerdict.rejected(ReplayRejection.implausibleScore);
  }
  for (var i = 1; i < shots.length; i++) {
    if (shots[i].step - shots[i - 1].step < kLaunchIntervalSteps) {
      return const ReplayVerdict.rejected(ReplayRejection.shotIntervalTooShort);
    }
  }

  final session = GameSession(seed, recordEvents: false);
  for (final record in shots) {
    final shot = Shot(record.vx, record.vy);
    if (!isValidShot(shot)) {
      return const ReplayVerdict.rejected(ReplayRejection.invalidShot);
    }
    while (session.stepCount < record.step && session.phase != GamePhase.ready) {
      if (session.phase == GamePhase.gameOver) break;
      session.step();
    }
    if (session.phase == GamePhase.ready && session.stepCount < record.step) {
      session.idle(record.step - session.stepCount);
    }
    if (session.stepCount != record.step || !session.tryShoot(shot)) {
      return const ReplayVerdict.rejected(ReplayRejection.shotNotReady);
    }
  }

  while (session.phase != GamePhase.ready && session.phase != GamePhase.gameOver) {
    session.step();
  }
  if (session.phase != GamePhase.gameOver) {
    return ReplayVerdict.rejected(ReplayRejection.notFinished, replayedScore: session.score);
  }
  if (session.score != claimedScore) {
    return ReplayVerdict.rejected(ReplayRejection.scoreMismatch, replayedScore: session.score);
  }
  return ReplayVerdict.valid(session.score);
}
