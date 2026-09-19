import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assets_content_repository.dart';
import 'content_repository.dart';
import 'local/app_database.dart';
import 'local/progress_repository.dart';
import 'models/passage.dart';
import 'models/topic.dart';
import 'models/voice_track.dart';
import 'user_preferences.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => AssetsContentRepository(),
);

final preferencesRepositoryProvider = Provider(
  (ref) => PreferencesRepository(),
);

final appDatabaseProvider = Provider((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(appDatabaseProvider)),
);

final bookmarkedIdsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(progressRepositoryProvider).bookmarkedIds(),
);

final progressByPassageProvider = FutureProvider<Map<String, PassageProgress>>(
  (ref) => ref.watch(progressRepositoryProvider).allProgress(),
);

final resumableProgressProvider = FutureProvider<PassageProgress?>(
  (ref) => ref.watch(progressRepositoryProvider).mostRecentUnfinished(),
);

final recentSessionsProvider = FutureProvider<List<PracticeSession>>(
  (ref) => ref.watch(progressRepositoryProvider).recentSessions(),
);

final practiceStatsProvider = FutureProvider<PracticeStats>(
  (ref) => ref.watch(progressRepositoryProvider).stats(),
);

/// Trình độ suy ra từ level của các bài đã luyện, không phải một hồ sơ riêng.
final practisedLevelProvider = FutureProvider<String?>((ref) async {
  final sessions = await ref.watch(recentSessionsProvider.future);
  if (sessions.isEmpty) return null;

  final counts = <String, int>{};
  for (final session in sessions) {
    final passage = await ref.watch(passageProvider(session.passageId).future);
    if (passage == null) continue;
    counts[passage.level] = (counts[passage.level] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;

  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
});

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

final voiceTrackProvider = FutureProvider.family<VoiceTrack?, String>(
  (ref, id) => ref.watch(contentRepositoryProvider).getVoiceTrack(id),
);

/// Danh sách bài của một topic, `durationMin` null = không lọc.
final passagesProvider =
    FutureProvider.family<List<Passage>, ({String topicId, int? durationMin})>(
      (ref, key) => ref
          .watch(contentRepositoryProvider)
          .getPassages(key.topicId, durationMin: key.durationMin),
    );
