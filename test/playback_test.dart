import 'package:echora/data/models/passage.dart';
import 'package:echora/features/player/playback/playback_clock.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

Passage _passage({List<String>? body}) {
  final sentences =
      body ??
      const [
        'One two three four five',
        'Six seven eight nine ten',
        'Eleven twelve thirteen fourteen fifteen',
      ];
  return Passage(
    id: 'test-01',
    topicId: 'test',
    title: 'Test',
    level: 'B1',
    durationMin: 2,
    wordCount: sentences.join(' ').split(' ').length,
    order: 1,
    body: sentences,
  );
}

void main() {
  group('PlaybackTimeline', () {
    test('total duration follows wordCount / wpm', () {
      final timeline = PlaybackTimeline.of(_passage(), 90);
      expect(timeline.wordCount, 15);
      expect(timeline.totalMs, (15 / 90 * 60000).round());
    });

    test('faster wpm shortens the passage proportionally', () {
      final slow = PlaybackTimeline.of(_passage(), 60);
      final fast = PlaybackTimeline.of(_passage(), 120);
      expect(slow.totalMs, fast.totalMs * 2);
    });

    test('sentence lookup covers every boundary', () {
      final timeline = PlaybackTimeline.of(_passage(), 60);
      expect(timeline.sentenceIndexAt(0), 0);
      expect(timeline.sentenceIndexAt(timeline.sentences[1].startMs), 1);
      expect(timeline.sentenceIndexAt(timeline.sentences[1].startMs - 1), 0);
      expect(timeline.sentenceIndexAt(timeline.totalMs), 2);
    });

    test('karaoke word lookup advances within a sentence', () {
      final timeline = PlaybackTimeline.of(_passage(), 60);
      final second = timeline.sentences[1];
      expect(timeline.wordIndexInSentenceAt(second.startMs), 0);
      expect(timeline.wordIndexInSentenceAt(second.words[3].startMs), 3);
      expect(timeline.wordIndexInSentenceAt(second.endMs - 1), 4);
    });

    test('seek snaps back to the start of the sentence', () {
      final timeline = PlaybackTimeline.of(_passage(), 60);
      final second = timeline.sentences[1];
      final midSentence = (second.startMs + second.endMs) ~/ 2;
      expect(timeline.snapToSentenceStart(midSentence), second.startMs);
      expect(timeline.snapToSentenceStart(-5000), 0);
    });

    test('word position survives a wpm change without losing progress', () {
      final slow = PlaybackTimeline.of(_passage(), 60);
      final fast = PlaybackTimeline.of(_passage(), 120);

      final atWord7 = slow.sentences[1].words[2].startMs;
      final position = slow.wordPositionAt(atWord7);
      final rebased = fast.msAtWordPosition(position);

      expect(fast.wordPositionAt(rebased), closeTo(position, 0.01));
      expect(fast.sentenceIndexAt(rebased), slow.sentenceIndexAt(atWord7));
    });

    test('multiplier is derived from wpm, rounded to one decimal', () {
      expect(multiplierOf(90), 1.0);
      expect(multiplierOf(70), 0.8);
      expect(multiplierOf(130), 1.4);
    });
  });

  group('PlaybackClock', () {
    late DateTime now;
    late PlaybackClock clock;

    setUp(() {
      now = DateTime(2026, 1, 1);
      clock = PlaybackClock(now: () => now)..setTotalMs(10000);
    });

    void advance(int ms) => now = now.add(Duration(milliseconds: ms));

    test('does not move while paused', () {
      advance(5000);
      expect(clock.elapsedMs, 0);
      expect(clock.isPlaying, isFalse);
    });

    test('pause then resume continues from the same position', () {
      clock.play();
      advance(2000);
      clock.pause();
      expect(clock.elapsedMs, 2000);

      advance(9000);
      expect(clock.elapsedMs, 2000);

      clock.play();
      advance(1000);
      expect(clock.elapsedMs, 3000);
    });

    test('seek keeps playing without jumping back', () {
      clock.play();
      advance(1000);
      clock.seekTo(6000);
      expect(clock.elapsedMs, 6000);
      advance(500);
      expect(clock.elapsedMs, 6500);
    });

    test('elapsed is clamped to the total', () {
      clock.play();
      advance(30000);
      expect(clock.elapsedMs, 10000);
      expect(clock.isFinished, isTrue);
    });

    test('playing again after finishing restarts from zero', () {
      clock.play();
      advance(30000);
      clock.pause();
      clock.play();
      expect(clock.elapsedMs, 0);
    });

    test('rebase moves the timebase without stopping playback', () {
      clock.play();
      advance(2000);
      clock.rebase(elapsedMs: 1000, totalMs: 5000);
      expect(clock.isPlaying, isTrue);
      expect(clock.elapsedMs, 1000);
      advance(250);
      expect(clock.elapsedMs, 1250);
    });
  });
}
