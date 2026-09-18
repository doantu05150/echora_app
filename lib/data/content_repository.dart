import 'models/passage.dart';
import 'models/topic.dart';

/// v1 đọc JSON trong assets, v2 sẽ gọi API. UI và controller không được biết
/// sự khác biệt — chỉ phụ thuộc interface này.
abstract interface class ContentRepository {
  Future<List<Topic>> getTopics();

  /// [durationMin] null = không lọc.
  Future<List<Passage>> getPassages(String topicId, {int? durationMin});

  Future<Passage?> getPassage(String id);
}
