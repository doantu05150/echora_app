import 'models/passage.dart';
import 'models/topic.dart';
import 'models/voice_track.dart';

/// v1 đọc JSON trong assets, v2 sẽ gọi API. UI và controller không được biết
/// sự khác biệt — chỉ phụ thuộc interface này.
abstract interface class ContentRepository {
  Future<List<Topic>> getTopics();

  /// [durationMin] null = không lọc.
  Future<List<Passage>> getPassages(String topicId, {int? durationMin});

  Future<Passage?> getPassage(String id);

  /// null khi bài chưa có giọng đọc mẫu — chế độ VOICE phải tự ẩn đi.
  Future<VoiceTrack?> getVoiceTrack(String passageId);
}
