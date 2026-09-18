import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assets_content_repository.dart';
import 'content_repository.dart';
import 'models/passage.dart';
import 'models/topic.dart';
import 'user_preferences.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => AssetsContentRepository(),
);

final preferencesRepositoryProvider = Provider(
  (ref) => PreferencesRepository(),
);

/// Giá trị mặc định cho buổi luyện. Player đọc một lần khi mở bài rồi tự giữ
/// state của nó — nếu Player watch provider này thì mỗi lần đổi tốc độ sẽ
/// dựng lại controller và mất tiến độ.
class PreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() =>
      ref.watch(preferencesRepositoryProvider).load();

  Future<void> save(UserPreferences value) async {
    state = AsyncData(value);
    await ref.read(preferencesRepositoryProvider).save(value);
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, UserPreferences>(
      PreferencesController.new,
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
