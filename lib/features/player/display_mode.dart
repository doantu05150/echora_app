enum DisplayMode {
  scroll,
  line,
  karaoke;

  static DisplayMode fromStorage(String? value) => switch (value) {
    'LINE' => DisplayMode.line,
    'KARAOKE' => DisplayMode.karaoke,
    _ => DisplayMode.scroll,
  };

  String get storageValue => switch (this) {
    DisplayMode.scroll => 'SCROLL',
    DisplayMode.line => 'LINE',
    DisplayMode.karaoke => 'KARAOKE',
  };
}
