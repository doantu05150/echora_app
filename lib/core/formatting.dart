import 'strings.dart';

const _weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/// `Thứ Tư, 18 tháng 9`
String formatVietnameseDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} tháng ${date.month}';

String greetingFor(DateTime time) {
  if (time.hour < 12) return Strings.greetingMorning;
  if (time.hour < 18) return Strings.greetingAfternoon;
  return Strings.greetingEvening;
}

/// `04:31` — luôn hai chữ số phút để chiều rộng không nhảy khi đang chạy.
String formatClock(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).floor();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// `1.0×` — hệ số chỉ là cách hiển thị của WPM.
String formatMultiplier(double multiplier) =>
    '${multiplier.toStringAsFixed(1)}×';
