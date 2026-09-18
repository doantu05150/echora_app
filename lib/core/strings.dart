/// Toàn bộ chuỗi hiển thị. Không để literal tiếng Việt trong widget.
abstract final class Strings {
  static const appName = 'Echora';
  static const appTagline = 'Luyện shadowing tiếng Anh';

  // Điều hướng
  static const navHome = 'Trang chủ';
  static const navProfile = 'Hồ sơ';
  static const back = 'Quay lại';

  // Home
  static const greetingMorning = 'Chào buổi sáng';
  static const greetingAfternoon = 'Chào buổi chiều';
  static const greetingEvening = 'Chào buổi tối';
  static String streakDays(int days) => '$days ngày liên tiếp';
  static const continueTitle = 'Đang dở';
  static const continueAction = 'Tiếp tục';
  static String remainingMinutes(int minutes) => 'Còn khoảng $minutes phút';
  static const emptyStateTitle = 'Bắt đầu bài đầu tiên';
  static const emptyStateBody =
      'Chọn một chủ đề bên dưới và đọc nhại theo đoạn văn trên màn hình.';
  static const emptyStateAction = 'Chọn chủ đề';
  static const topicsSectionTitle = 'Chủ đề';
  static const comingSoon = 'Sắp có';

  // Topic
  static const filterAll = 'Tất cả';
  static String filterMinutes(int minutes) => '$minutes phút';
  static String passageCount(int count) => '$count bài';
  static String durationLabel(int minutes) => '$minutes phút';
  static String completedPercent(int percent) => 'đã xong $percent%';
  static const notStarted = 'chưa học';
  static const topicEmpty = 'Chưa có bài nào ở độ dài này.';
  static const bookmarkAdd = 'Lưu bài';
  static const bookmarkRemove = 'Bỏ lưu';

  // Player
  static const playerRecordingTeaser = 'Ghi âm & so sánh giọng · sắp có';
  static const play = 'Chạy';
  static const pause = 'Tạm dừng';
  static const seekBack = 'Lùi 10 giây';
  static const seekForward = 'Tiến 10 giây';
  static const openSettings = 'Cài đặt buổi luyện';
  static String wpmLabel(int wpm) => '$wpm từ/phút';
  static String passageIndex(int order) => 'Bài ${order.toString().padLeft(2, '0')}';

  // Sheet cài đặt
  static const sheetTitle = 'Cài đặt buổi luyện';
  static const sheetSpeed = 'Tốc độ';
  static const sheetPresetSlow = 'Chậm';
  static const sheetPresetNormal = 'Vừa';
  static const sheetPresetFast = 'Nhanh';
  static const sheetPresetVeryFast = 'Rất nhanh';
  static const sheetDuration = 'Độ dài đoạn';
  static const sheetDurationHint = 'Áp dụng cho bài kế tiếp, không đổi bài đang chạy.';
  static const sheetDisplayMode = 'Kiểu chạy chữ';
  static const sheetModeScroll = 'Cuộn đều';
  static const sheetModeScrollHint = 'Chữ trôi liên tục, câu giữa màn được làm nổi.';
  static const sheetModeLine = 'Từng câu';
  static const sheetModeLineHint = 'Chữ đứng yên, nhảy sang câu kế tiếp.';
  static const sheetModeKaraoke = 'Karaoke';
  static const sheetModeKaraokeHint = 'Highlight chạy theo từng từ trong câu.';
  static const sheetFontSize = 'Cỡ chữ';
  static const sheetKeepScreenOn = 'Giữ màn hình sáng';
  static const sheetApply = 'Áp dụng';

  // Profile
  static const profileTitle = 'Hồ sơ';
  static const statStreak = 'Chuỗi ngày';
  static const statMinutes = 'Phút đã luyện';
  static const statPassages = 'Bài đã học';
  static const tabSaved = 'Đã lưu';
  static const tabHistory = 'Lịch sử';
  static const savedEmpty = 'Chưa lưu bài nào.';
  static const historyEmpty = 'Chưa có buổi luyện nào.';

  // Settings
  static const settingsTitle = 'Cài đặt';
  static const settingsDefaults = 'Mặc định khi luyện';
  static const settingsDevice = 'Thiết bị';
  static const settingsHaptic = 'Rung mỗi câu mới';
  static const settingsUpcoming = 'Sắp có';
  static const settingsRecording = 'Ghi âm & chấm phát âm';
  static const settingsVersionTag = 'V2';
  static const settingsOther = 'Khác';
  static const settingsLanguage = 'Ngôn ngữ';
  static const settingsLanguageValue = 'Tiếng Việt';
  static const settingsAbout = 'Về ứng dụng';
}
