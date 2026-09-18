import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assets_content_repository.dart';
import 'content_repository.dart';
import 'models/passage.dart';
import 'models/topic.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => AssetsContentRepository(),
);

final topicsProvider = FutureProvider<List<Topic>>(
  (ref) => ref.watch(contentRepositoryProvider).getTopics(),
);

final topicProvider = FutureProvider.family<Topic?, String>((ref, id) async {
  final topics = await ref.watch(topicsProvider.future);
  for (final topic in topics) {
    if (topic.id == id) return topic;
  }
  return null;
});

final passageProvider = FutureProvider.family<Passage?, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).getPassage(id),
);

/// Danh sách bài của một topic, `durationMin` null = không lọc.
final passagesProvider =
    FutureProvider.family<List<Passage>, ({String topicId, int? durationMin})>(
      (ref, key) => ref
          .watch(contentRepositoryProvider)
          .getPassages(key.topicId, durationMin: key.durationMin),
    );
