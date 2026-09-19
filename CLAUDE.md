# CLAUDE.md

Context cho Claude Code. Đọc file này trước khi làm bất cứ việc gì trong repo.

## App là gì

**Echora** — ứng dụng luyện **shadowing tiếng Anh**. Một đoạn văn tiếng Anh chạy trên
màn hình theo tốc độ cấu hình được, người học đọc nhại theo. Không có audio ở v1.

Người dùng mục tiêu: người Việt học tiếng Anh, trình độ A2–B2. Giao diện tiếng Việt,
nội dung luyện tập tiếng Anh.

## Stack

- Flutter (stable 3.41+), Dart 3.11, Material 3 (chỉ dùng component, **không** dùng
  color scheme sinh từ seed — xem `docs/design-tokens.md`)
- State: `flutter_riverpod`. Kiến trúc: screen (widget thuần) → notifier → repository
- Navigation: `go_router`
- Preference: `shared_preferences`
- Bookmark / progress / lịch sử: `sqflite`
- Giọng đọc mẫu: mp3 render sẵn trong `assets/audio/`, phát bằng `just_audio`
- Nội dung: JSON trong `assets/content/` ở v1, **thiết kế repository để sau thay bằng
  API mà không đổi UI layer**
- Không thêm package mới khi chưa hỏi

## Quy ước

- Cấu trúc: `lib/features/<feature>/` — `home`, `topic`, `player`, `profile`, `settings`;
  dùng chung ở `lib/core/`, `lib/data/`, `lib/ui/`
- Mỗi màn: `xxx_screen.dart` (widget nhận state + callback), `xxx_controller.dart`
  (Riverpod notifier), `xxx_state.dart`
- Widget không tự lấy dữ liệu, không giữ business logic. State đi xuống, event đi lên.
- **Không hardcode màu / khoảng cách / cỡ chữ / radius trong widget.** Tất cả qua token
  trong `lib/ui/theme/` — dùng `context.colors`, `context.typography`, `AppSpacing`,
  `AppRadius`, `AppSize`.
- Không viết comment giải thích code hiển nhiên. Comment chỉ cho quyết định khác thường.
- Chuỗi hiển thị vào `lib/core/strings.dart`, không để literal trong widget.

## Lệnh

```
flutter analyze
flutter test
flutter run -d web-server --web-port 5599   # preview nhanh khi làm UI
flutter build apk --debug
python3 tool/generate_icons.py              # sinh lại logo + app icon
python3 tool/generate_voice.py              # render giọng đọc mẫu (xem header file)
```

## Tài liệu trong repo

- `docs/spec.md` — đặc tả 6 màn, luồng, schema JSON, thứ tự làm
- `docs/design-tokens.md` — màu, font, spacing, radius (bắt buộc đọc trước khi làm UI)

Spec gốc viết cho Android/Compose; mọi thứ về **hành vi, số liệu, luồng, schema** giữ
nguyên, chỉ tên công nghệ là đổi (DataStore → shared_preferences, Room → sqflite,
Composable → widget).

Mockup gốc (canvas, xem được luồng bấm): https://claude.ai/artifact/M9kMeQdPBcpMD5Wn54t3Ww

## Ranh giới

- Phần **ghi âm / chấm điểm phát âm** là v2. Không làm ở v1, nhưng đừng thiết kế
  kiến trúc chặn đường nó (xem mục "Chuẩn bị cho v2" trong spec).
- Giọng đọc mẫu đã làm ở v1 (chế độ `VOICE`) bằng audio render sẵn, không phải TTS
  lúc chạy — xem `docs/spec.md` mục 2.4.
- Không tự thêm analytics, ads, crash reporting khi chưa được yêu cầu.
- Trước khi làm một feature mới, đọc `docs/spec.md` phần tương ứng; nếu spec mâu thuẫn
  với yêu cầu trong chat, hỏi lại chứ đừng tự chọn.
