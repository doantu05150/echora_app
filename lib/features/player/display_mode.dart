enum DisplayMode {
  scroll,
  line,
  karaoke,
  voice;

  static DisplayMode fromStorage(String? value) => switch (value) {
    'LINE' => DisplayMode.line,
    'KARAOKE' => DisplayMode.karaoke,
    'VOICE' => DisplayMode.voice,
    _ => DisplayMode.scroll,
  };

  String get storageValue => switch (this) {
    DisplayMode.scroll => 'SCROLL',
    DisplayMode.line => 'LINE',
    DisplayMode.karaoke => 'KARAOKE',
    DisplayMode.voice => 'VOICE',
  };

  /// Chế độ cần file giọng đọc mẫu của bài, không phải bài nào cũng có.
  bool get needsVoice => this == DisplayMode.voice;
}
