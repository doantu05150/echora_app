import 'package:echora/data/models/passage.dart';
import 'package:echora/data/models/voice_track.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

const _sentences = [
  'One two three four five six.',
  'Seven eight nine ten.',
  'Eleven twelve.',
];

final _passage = Passage(
  id: 'voice-01',
  topicId: 'voice',
  title: 'Voice',
  level: 'A2',
  durationMin: 1,
  wordCount: 12,
  order: 1,
  body: _sentences,
);

/// 12 từ, 6000ms tiếng nói + 2 khoảng lặng 350ms → đúng 120 wpm.
const _track = VoiceTrack(
  passageId: 'voice-01',
  audioAsset: 'assets/audio/voice-01.mp3',
  voice: 'am_michael',
  nativeWpm: 120,
  totalMs: 6700,
  sentences: [
    VoiceSentence(index: 0, startMs: 0, endMs: 3000),
    VoiceSentence(index: 1, startMs: 3350, endMs: 5000),
    VoiceSentence(index: 2, startMs: 5350, endMs: 6000),
  ],
);

void main() {
  test('at native wpm the timeline keeps the measured timings', () {
    final timeline = PlaybackTimeline.ofVoice(_passage, _track, 120);

    expect(timeline.sentences.length, 3);
    expect(timeline.sentences[0].startMs, 0);
    expect(timeline.sentences[0].endMs, 3000);
    expect(timeline.sentences[1].startMs, 3350);
    expect(timeline.totalMs, 6700);
    expect(timeline.wordCount, 12);
  });

  test('a higher wpm shortens every timing by the same factor', () {
    final timeline = PlaybackTimeline.ofVoice(_passage, _track, 240);

    expect(timeline.sentences[1].startMs, 1675);
    expect(timeline.sentences[2].endMs, 3000);
    expect(timeline.totalMs, 3350);
  });

  test('speedOf maps wpm onto the playback rate of the audio', () {
    expect(_track.speedAt(120), closeTo(1.0, 0.001));
    expect(_track.speedAt(60), closeTo(0.5, 0.001));
    expect(_track.speedAt(180), closeTo(1.5, 0.001));
  });

  test('words are spread across the sentence they belong to', () {
    final timeline = PlaybackTimeline.ofVoice(_passage, _track, 120);
    final first = timeline.sentences[0];

    expect(first.words.length, 6);
    expect(first.words.first.startMs, 0);
    expect(first.words.last.endMs, 3000);
    expect(first.words.first.globalIndex, 0);
    expect(timeline.sentences[1].words.first.globalIndex, 6);

    for (var i = 1; i < first.words.length; i++) {
      expect(first.words[i].startMs, greaterThanOrEqualTo(first.words[i - 1].endMs));
    }
  });

  test('the silence between sentences belongs to neither sentence', () {
    final timeline = PlaybackTimeline.ofVoice(_passage, _track, 120);

    expect(timeline.sentenceIndexAt(3100), 0);
    expect(timeline.sentenceIndexAt(3350), 1);
  });

  test('changing wpm keeps the position as a share of the passage', () {
    final slow = PlaybackTimeline.ofVoice(_passage, _track, 120);
    final fast = PlaybackTimeline.ofVoice(_passage, _track, 240);

    final moved = fast.msAtWordPosition(slow.wordPositionAt(3350));
    expect(moved, 1675);
  });
}
