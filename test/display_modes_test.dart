import 'package:echora/data/models/passage.dart';
import 'package:echora/features/player/playback/playback_timeline.dart';
import 'package:echora/features/player/widgets/karaoke_text_view.dart';
import 'package:echora/features/player/widgets/line_text_view.dart';
import 'package:echora/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sentences = [
  'First sentence here.',
  'Second sentence here.',
  'Third sentence here.',
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

final _timeline = PlaybackTimeline.of(_passage, 90);

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SizedBox(width: 360, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('LINE', () {
    testWidgets('shows the current sentence with its neighbours', (
      tester,
    ) async {
      await _pump(
        tester,
        LineTextView(
          timeline: _timeline,
          elapsedMs: _timeline.sentences[1].startMs,
          fontSizeSp: 29,
          accent: AppColors.light.clay,
        ),
      );

      expect(find.text(_sentences[0]), findsOneWidget);
      expect(find.text(_sentences[1]), findsOneWidget);
      expect(find.text(_sentences[2]), findsOneWidget);
    });

    testWidgets('drops the leading neighbour on the first sentence', (
      tester,
    ) async {
      await _pump(
        tester,
        LineTextView(
          timeline: _timeline,
          elapsedMs: 0,
          fontSizeSp: 29,
          accent: AppColors.light.clay,
        ),
      );

      expect(find.text(_sentences[0]), findsOneWidget);
      expect(find.text(_sentences[1]), findsOneWidget);
      expect(find.text(_sentences[2]), findsNothing);
    });
  });

  group('KARAOKE', () {
    Future<void> pumpAt(WidgetTester tester, int elapsedMs) => _pump(
      tester,
      KaraokeTextView(
        timeline: _timeline,
        elapsedMs: elapsedMs,
        fontSizeSp: 29,
        accent: AppColors.light.clay,
      ),
    );

    List<Color?> wordColors(WidgetTester tester) {
      final richText = tester.widget<RichText>(find.byType(RichText));
      final colors = <Color?>[];
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          colors.add(span.style?.color);
        }
        return true;
      });
      return colors;
    }

    testWidgets('renders only the sentence being read', (tester) async {
      await pumpAt(tester, 0);

      expect(find.textContaining('First'), findsOneWidget);
      expect(find.textContaining('Second'), findsNothing);
    });

    testWidgets('words already read take the topic colour', (tester) async {
      final sentence = _timeline.sentences.first;
      await pumpAt(tester, sentence.words[2].startMs);

      final colors = wordColors(tester);
      expect(colors[0], AppColors.light.clay.base);
      expect(colors[1], AppColors.light.clay.base);
      expect(colors[2], AppColors.light.ink);
    });

    testWidgets('the highlight advances with time', (tester) async {
      final sentence = _timeline.sentences.first;

      await pumpAt(tester, sentence.words[0].startMs);
      expect(wordColors(tester)[0], AppColors.light.ink);

      await pumpAt(tester, sentence.words[1].startMs);
      expect(wordColors(tester)[0], AppColors.light.clay.base);
      expect(wordColors(tester)[1], AppColors.light.ink);
    });
  });
}
