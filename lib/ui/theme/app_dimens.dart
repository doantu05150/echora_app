/// Thang spacing 4dp, radius và kích thước chạm. Không hardcode dp trong màn hình.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const sm = 8.0;
  static const smPlus = 10.0;
  static const md = 12.0;
  static const mdPlus = 14.0;
  static const lg = 16.0;
  static const lgPlus = 18.0;
  static const xl = 20.0;
  static const xlPlus = 22.0;
  static const xxl = 28.0;

  static const screenHorizontal = 20.0;
  static const screenTop = 28.0;
  static const screenBottom = 20.0;

  /// Khoảng cách giữa các khối lớn trong một màn.
  static const sectionGap = 18.0;

  /// Padding trong list item.
  static const cardPadding = 14.0;

  /// Padding trong thẻ lớn.
  static const cardPaddingLarge = 18.0;

  /// Gap giữa các ô trong lưới.
  static const gridGap = 12.0;
}

abstract final class AppRadius {
  static const sm = 7.0;
  static const md = 13.0;
  static const lg = 18.0;
  static const xl = 21.0;
  static const sheet = 28.0;

  /// Dùng cho chip / nút tròn / avatar: bán kính lớn hơn nửa chiều cao.
  static const pill = 999.0;
}

abstract final class AppSize {
  static const minTouchTarget = 44.0;
  static const playButton = 72.0;
  static const seekButton = 48.0;
  static const iconButton = 44.0;
  static const bottomNavItem = 50.0;
}
