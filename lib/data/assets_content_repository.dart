import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'content_repository.dart';
import 'models/passage.dart';
import 'models/topic.dart';
import 'models/voice_track.dart';

class AssetsContentRepository implements ContentRepository {
  AssetsContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  List<Topic>? _topics;
  final Map<String, List<Passage>> _passagesByTopic = {};
  final Map<String, VoiceTrack?> _voiceTracks = {};

  @override
  Future<List<Topic>> getTopics() async {
    final cached = _topics;
    if (cached != null) return cached;

    final raw = await _bundle.loadString('assets/content/topics.json');
    final topics = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _topics = topics;
  }

  @override
  Future<List<Passage>> getPassages(String topicId, {int? durationMin}) async {
    final all = await _loadTopicPassages(topicId);
    if (durationMin == null) return all;
    return all.where((p) => p.durationMin == durationMin).toList();
  }

  @override
  Future<Passage?> getPassage(String id) async {
    for (final list in _passagesByTopic.values) {
      for (final passage in list) {
        if (passage.id == id) return passage;
      }
    }

    final topicId = id.contains('-') ? id.substring(0, id.lastIndexOf('-')) : id;
    final list = await _loadTopicPassages(topicId);
    for (final passage in list) {
      if (passage.id == id) return passage;
    }
    return null;
  }

  @override
  Future<VoiceTrack?> getVoiceTrack(String passageId) async {
    if (_voiceTracks.containsKey(passageId)) return _voiceTracks[passageId];

    final String raw;
    try {
      raw = await _bundle.loadString('assets/content/voice/$passageId.json');
    } on FlutterError {
      return _voiceTracks[passageId] = null;
    }

    return _voiceTracks[passageId] = VoiceTrack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<List<Passage>> _loadTopicPassages(String topicId) async {
    final cached = _passagesByTopic[topicId];
    if (cached != null) return cached;

    final String raw;
    try {
      raw = await _bundle.loadString('assets/content/passages/$topicId.json');
    } on FlutterError {
      return _passagesByTopic[topicId] = const [];
    }

    final passages = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Passage.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _passagesByTopic[topicId] = passages;
  }
}
