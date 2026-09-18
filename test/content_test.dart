import 'dart:convert';
import 'dart:io';

import 'package:echora/data/models/passage.dart';
import 'package:echora/data/models/topic.dart';
import 'package:flutter_test/flutter_test.dart';

const _referenceWpm = 90;
const _allowedDurations = {2, 3, 5, 7};
const _colorTokens = {'clay', 'teal', 'violet', 'amber', 'rose'};

List<Topic> _loadTopics() {
  final raw = File('assets/content/topics.json').readAsStringSync();
  return (jsonDecode(raw) as List<dynamic>)
      .map((e) => Topic.fromJson(e as Map<String, dynamic>))
      .toList();
}

List<Passage> _loadPassages(String topicId) {
  final raw = File(
    'assets/content/passages/$topicId.json',
  ).readAsStringSync();
  return (jsonDecode(raw) as List<dynamic>)
      .map((e) => Passage.fromJson(e as Map<String, dynamic>))
      .toList();
}

void main() {
  final topics = _loadTopics();

  test('topic ids are unique and ordered', () {
    expect(topics.map((t) => t.id).toSet().length, topics.length);
    final orders = topics.map((t) => t.order).toList()..sort();
    expect(orders, List.generate(topics.length, (i) => i + 1));
  });

  test('topic colorToken maps to a known accent', () {
    for (final topic in topics) {
      expect(_colorTokens, contains(topic.colorToken), reason: topic.id);
    }
  });

  for (final topic in topics.where((t) => !t.comingSoon)) {
    group('passages of ${topic.id}', () {
      final passages = _loadPassages(topic.id);

      test('file is non-empty and consistently ordered', () {
        expect(passages, isNotEmpty);
        final orders = passages.map((p) => p.order).toList()..sort();
        expect(orders, List.generate(passages.length, (i) => i + 1));
        expect(passages.map((p) => p.id).toSet().length, passages.length);
      });

      test('every passage belongs to its topic file', () {
        for (final p in passages) {
          expect(p.topicId, topic.id, reason: p.id);
        }
      });

      test('durationMin is one of the filterable values', () {
        for (final p in passages) {
          expect(_allowedDurations, contains(p.durationMin), reason: p.id);
        }
      });

      test('wordCount matches the body and the declared duration', () {
        for (final p in passages) {
          final real = p.body.join(' ').split(RegExp(r'\s+')).length;
          expect(p.wordCount, real, reason: '${p.id} declared wordCount');

          final target = p.durationMin * _referenceWpm;
          expect(
            (real - target).abs() / target,
            lessThanOrEqualTo(0.05),
            reason: '${p.id} is $real words, expected ~$target',
          );
        }
      });

      test('body is split into sentences, not one blob', () {
        for (final p in passages) {
          expect(p.body.length, greaterThan(4), reason: p.id);
          for (final sentence in p.body) {
            expect(sentence.trim(), sentence, reason: p.id);
            expect(sentence, isNot(contains('  ')), reason: p.id);
            expect(
              sentence.split(' ').length,
              lessThan(30),
              reason: '${p.id} has an unsplit sentence: $sentence',
            );
          }
        }
      });
    });
  }
}
