import 'package:echora/data/models/passage.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:echora/features/player/widgets/scroll_text_view.dart';
import 'package:echora/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sentences = [
  'First sentence of the passage.',
  'Second sentence of the passage.',
  'Third sentence of the passage.',
];

final _passage = Passage(
  id: 'test-01',
  topicId: 'test',
  title: 'Test',
  level: 'B1',
  durationMin: 2,
  wordCount: _sentences.join(' ').split(' ').length,
  order: 1,
  body: _sentences,
);

Future<void> _pumpAt(WidgetTester tester, int elapsedMs, PlaybackTimeline t) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 600,
          child: ScrollTextView(
            timeline: t,
            elapsedMs: elapsedMs,
            fontSizeSp: 29,
          ),
        ),
      ),
    ),
  );
}

void main() {
  final timeline = PlaybackTimeline.of(_passage, 90);

  testWidgets('renders every sentence', (tester) async {
    await _pumpAt(tester, 0, timeline);
    for (final sentence in _sentences) {
      expect(find.text(sentence), findsOneWidget);
    }
  });

  testWidgets('the text block is laid out inside the viewport', (tester) async {
    await _pumpAt(tester, 0, timeline);
    final box = tester.renderObject<RenderBox>(find.byType(ScrollTextView));
    expect(box.size.height, 600);
    expect(box.size.width, 360);
  });

  testWidgets('the sentence being read crosses the vertical centre', (
    tester,
  ) async {
    final span = timeline.sentences[1];
    await _pumpAt(tester, (span.startMs + span.endMs) ~/ 2, timeline);

    final rect = tester.getRect(find.text(_sentences[1]));
    expect(rect.top, lessThanOrEqualTo(300));
    expect(rect.bottom, greaterThanOrEqualTo(300));
  });

  testWidgets('text scrolls up as time advances', (tester) async {
    await _pumpAt(tester, 0, timeline);
    final start = tester.getRect(find.text(_sentences[0])).top;

    await _pumpAt(tester, timeline.sentences[1].startMs, timeline);
    final later = tester.getRect(find.text(_sentences[0])).top;

    expect(later, lessThan(start));
  });
}
