# Spec — Shadowing English App (v1)

## 1. Khái niệm

| Thuật ngữ | Nghĩa |
|---|---|
| **Topic** | Chủ đề (Daily Life, Business…). Mỗi topic có một màu riêng. |
| **Passage** | Một đoạn văn để luyện. Thuộc đúng một topic. |
| **Session** | Một lần luyện một passage, có tốc độ / độ dài / kiểu chạy chữ riêng. |
| **WPM** | Số từ hiển thị mỗi phút. Đây là **nguồn sự thật duy nhất** về tốc độ. |

## 2. Quyết định đã chốt

### 2.1 Tốc độ: WPM là thật, `×` chỉ là cách hiển thị

- State lưu **một giá trị duy nhất**: `wpm: Int`, khoảng 50–160, bước 5.
- Chip trên màn Player hiển thị **hệ số**: `multiplier = wpm / 90f`, làm tròn 1 chữ số → `0.8×`, `1.0×`, `1.4×`.
- Sheet cài đặt hiển thị **số WPM** kèm slider và 4 preset: Chậm 70 / Vừa 90 / Nhanh 110 / Rất nhanh 130.
- `90` là WPM tham chiếu (= `1.0×`), đặt thành hằng `REFERENCE_WPM`.
- **Không** lưu multiplier vào DataStore. Chỉ lưu `wpm`. Multiplier luôn tính lại từ `wpm`.

### 2.2 Độ dài đoạn: lọc, không cắt

- Mỗi passage có `durationMin` cố định trong JSON, thuộc `{2, 3, 5, 7}`.
- Chọn "3 phút" ở màn Topic = **lọc** danh sách, không cắt text.
- `durationMin` là độ dài ở WPM tham chiếu (90). Thời lượng thực tế hiển thị trong Player phải tính lại:
  `estimatedSeconds = wordCount / wpm * 60`. Ở 130 WPM, bài "3 phút" hiện `02:05` — hiện số thật, đừng hiện `03:00`.
- Sheet cài đặt trong Player vẫn có nhóm "Độ dài đoạn": ở đây nó là **bộ lọc cho bài kế tiếp**, không đổi bài đang chạy. Nhãn phải nói rõ điều đó.

### 2.3 Kiểu chạy chữ

Bốn kiểu, người dùng chọn trong sheet:

| Kiểu | Hành vi |
|---|---|
| `SCROLL` | Toàn bộ text cuộn đều liên tục từ dưới lên, tốc độ pixel/giây suy ra từ WPM. Mọi câu cùng một màu, **không** highlight câu đang đọc — chỉ có chuyển động cuộn. |
| `LINE` | Text đứng yên, nhảy **snap** sang câu kế tiếp khi hết thời lượng câu đó. Có animation chuyển mượt ~250ms. |
| `KARAOKE` | Câu đứng yên, highlight chạy **theo từng từ** trong câu. Từ đã đọc đổi màu. |
| `VOICE` | Chữ trôi y như `SCROLL`, kèm giọng đọc mẫu. Chi tiết ở 2.4. |

**Cả 4 phải dùng chung một `PlaybackClock`.** Đừng viết bộ đếm thời gian riêng cho từng kiểu — đó là cách chắc chắn nhất để chúng lệch nhau khi pause/seek.

```
PlaybackClock
  ├─ elapsedMs: StateFlow<Long>      // nguồn sự thật duy nhất
  ├─ play() / pause() / seekTo(ms)
  └─ totalMs = wordCount / wpm * 60_000

ScrollRenderer   đọc elapsedMs → scrollOffset
LineRenderer     đọc elapsedMs → currentSentenceIndex
KaraokeRenderer  đọc elapsedMs → currentSentenceIndex + currentWordIndex
```

Timing tính sẵn một lần khi mở passage: mỗi câu và mỗi từ có `startMs` / `endMs` dựa trên số từ và WPM. Renderer chỉ tra bảng theo `elapsedMs`, không tự tính.

> Lưu ý thực tế: mỗi kiểu là một lần nhân phần rủi ro nhất của app. Thứ tự:
> `SCROLL` chạy đúng và mượt trước → tách `PlaybackClock` ra → thêm `LINE` (dễ nhất, chỉ tra index)
> → `KARAOKE` → `VOICE`. Nếu `SCROLL` chưa mượt 60fps thì đừng làm tiếp.

### 2.4 `VOICE` — cuộn đều kèm giọng đọc

Giọng đọc **render sẵn** thành mp3 trong assets, không dùng TTS trên máy: giọng
on-device phụ thuộc engine của từng máy và không có mốc thời gian đáng tin.

`tool/generate_voice.py` chạy Kokoro trên máy dev, tổng hợp **từng câu một** rồi
mới ghép lại. Vì thế độ dài mỗi câu đo được chính xác từ số mẫu audio — không
cần forced alignment, không cần ffmpeg. Kết quả ghi ra:

- `assets/audio/<passageId>.mp3`
- `assets/content/voice/<passageId>.json` — `nativeWpm` (tốc độ đọc thật, đo
  sau khi render) và `startMs` / `endMs` của từng câu.

Bảng timing của `VOICE` **sinh từ mốc đo được** (`PlaybackTimeline.ofVoice`),
không tính từ WPM như ba kiểu kia. Đây là điều kiện để chữ và tiếng không trôi
lệch nhau.

Ràng buộc:

- **Clock vẫn là nguồn sự thật.** Audio bám theo clock: mỗi lần clock đổi trạng
  thái thì tua audio về đúng mốc, và cứ 2 giây kiểm tra lệch một lần, quá
  `220ms` mới tua (`VoicePlayback`).
- **Tốc độ ăn theo WPM**: `speed = wpm / nativeWpm`, đặt vào `just_audio` (giữ
  nguyên cao độ).
- **Sàn `kVoiceMinWpm = 90`.** Audio render ở ~100 wpm nên khi phát chỉ việc
  tăng tốc; kéo chậm quá nhiều thì méo tiếng. Vào chế độ này mà WPM đang thấp
  hơn thì nâng luôn giá trị đã lưu, không để sheet và tiếng nói hai số khác nhau.
- Bài **chưa có** file giọng: mục `VOICE` trong sheet bị mờ đi; nếu preference
  đang là `VOICE` thì rơi về chạy chữ im lặng, không chặn người học.

## 3. Màn hình

### 3.1 Home (`home/`)

- Header: ngày hôm nay + lời chào, chip streak (số ngày liên tiếp).
- Card "đang dở": passage gần nhất chưa hoàn thành, hiện % + thời gian còn lại, bấm vào resume đúng vị trí đã dừng. **Không có bài đang dở thì ẩn card, đừng hiện card rỗng** — thay bằng card "Bắt đầu bài đầu tiên".
- Lưới chủ đề 2 cột. Topic chưa có nội dung (`comingSoon: true`) hiện xám, không bấm được.
- Bottom nav 2 tab: Trang chủ / Hồ sơ.

### 3.2 Topic (`topic/`)

- Header ăn màu của topic, có mô tả ngắn.
- Hàng filter độ dài: Tất cả / 2 / 3 / 5 / 7 phút.
- Danh sách passage: số thứ tự, tiêu đề, `độ dài · level · % hoàn thành`, icon bookmark.
- Passage đang dở có viền nhấn và icon play thay vì bookmark.

### 3.3 Player (`player/`) — màn quan trọng nhất

- Top bar: back, `topic · day`, tiêu đề bài, nút bookmark.
- Vùng text chiếm phần lớn màn, render theo `DisplayMode` đang chọn.
- Progress bar + `thời gian đã chạy / WPM / tổng thời gian`.
- Hàng điều khiển: chip `1.0×` (mở sheet) · lùi 10s · play/pause 72dp · tiến 10s · icon cài đặt (mở sheet).
- Dải "Ghi âm & so sánh giọng · sắp có" — disabled, giữ chỗ cho v2.

Yêu cầu hành vi:
- Đổi WPM **giữa chừng** không được reset tiến độ. Giữ nguyên vị trí từ hiện tại, tính lại bảng timing từ vị trí đó.
- Pause rồi resume không được giật hay nhảy vị trí.
- Tua ±10s theo **thời gian**, rồi snap về đầu câu gần nhất (tua vào giữa câu thì không shadowing được).
- Lưu vị trí đang đọc mỗi ~5 giây để resume được sau khi thoát app.
- Giữ màn hình sáng khi đang play (`FLAG_KEEP_SCREEN_ON`), tắt khi pause.

### 3.4 Sheet cài đặt buổi luyện (`player/settings/`)

Bottom sheet, mở từ Player. Nội dung: tốc độ (slider WPM + 4 preset), độ dài đoạn (lọc bài kế tiếp), kiểu chạy chữ (4 lựa chọn), cỡ chữ (slider 20–40sp), giữ màn hình sáng (toggle), nút Áp dụng. Khi đang chọn `VOICE`, slider WPM bắt đầu từ 90 và preset dưới mức đó bị ẩn.

Thay đổi áp dụng **ngay khi chỉnh**, nút Áp dụng chỉ để đóng sheet. Đừng bắt người dùng bấm Áp dụng mới thấy hiệu quả — họ cần thấy tốc độ đổi để chọn.

### 3.5 Profile (`profile/`)

Avatar + tên + trình độ, 3 thẻ stat (chuỗi ngày / tổng phút luyện / số bài đã học), 2 tab: Đã lưu (bookmark) và Lịch sử.

### 3.6 Settings (`settings/`)

Nhóm "Mặc định khi luyện" (4 mục, mở lại sheet của Player), "Thiết bị" (giữ màn sáng, rung mỗi câu mới), "Sắp có" (ghi âm — disabled, nhãn V2), "Khác" (ngôn ngữ, về ứng dụng).

## 4. Điều hướng

```
Home ──► Topic ──► Player ──► SettingsSheet
  │                  ▲
  └──► Profile ──────┘ (từ bookmark / lịch sử)
         └──► Settings ──► SettingsSheet
```

## 5. Dữ liệu

### `assets/topics.json`

```json
[
  {
    "id": "daily-life",
    "title": "Daily Life",
    "description": "Thói quen, sinh hoạt và cuộc sống thường ngày.",
    "colorToken": "clay",
    "levelRange": "A2-B1",
    "order": 1,
    "comingSoon": false
  }
]
```

`colorToken` ∈ `clay | teal | violet | amber | rose` — map sang màu trong `design-tokens.md`.
**Không để mã hex trong JSON**, để app đổi theme được.

### `assets/passages/daily-life.json`

```json
[
  {
    "id": "daily-life-09",
    "topicId": "daily-life",
    "title": "The Power of Small Habits",
    "level": "B1",
    "durationMin": 3,
    "wordCount": 270,
    "order": 9,
    "body": [
      "Nine days ago, this was just a simple idea.",
      "Today, it is becoming a strong habit."
    ]
  }
]
```

**`body` là mảng câu, không phải một chuỗi dài.** Cả 4 kiểu chạy chữ, việc snap khi tua, giọng đọc render theo câu, và ghi âm theo câu ở v2 đều cần ranh giới câu. Tách câu ở runtime bằng regex là nguồn bug (dấu chấm trong `Mr.`, `U.S.`, số thập phân).

`wordCount` tính sẵn khi tạo nội dung, đừng đếm lại lúc chạy.

### Room

```
BookmarkEntity(passageId, createdAt)
ProgressEntity(passageId, positionMs, completedAt?, lastOpenedAt)
SessionEntity(id, passageId, startedAt, durationSec, wpm, displayMode)   // cho Lịch sử + stats
```

Streak tính từ `SessionEntity`: số ngày liên tiếp gần nhất có ít nhất một session.

### DataStore

`wpm: Int = 90`, `preferredDurationMin: Int = 3`, `displayMode: String = "SCROLL"`,
`fontSizeSp: Int = 29`, `keepScreenOn: Boolean = true`, `hapticOnSentence: Boolean = false`.

### Repository

```kotlin
interface ContentRepository {
    suspend fun getTopics(): List<Topic>
    suspend fun getPassages(topicId: String, durationMin: Int? = null): List<Passage>
    suspend fun getPassage(id: String): Passage?
}
```

v1: `AssetsContentRepository` đọc JSON. v2: `RemoteContentRepository` gọi API — **UI và ViewModel không được biết sự khác biệt**.

## 6. Thứ tự triển khai

1. Theme + token (`design-tokens.md`) — làm đầu tiên, mọi màn sau đó dùng lại
2. Model + `AssetsContentRepository` + JSON mẫu (2 topic, mỗi topic 6 bài là đủ để test)
3. Home + Topic + navigation
4. **`PlaybackClock` + Player kiểu `SCROLL`** — phần rủi ro nhất, làm sớm, test kỹ pause/seek/đổi WPM
5. Sheet cài đặt + DataStore
6. `LINE` mode
7. `KARAOKE` mode
8. Room: bookmark, progress, resume
9. Profile + Lịch sử + stats + streak
10. Settings

## 7. Chuẩn bị cho v2 (không code ở v1)

Ghi âm nhại theo · so sánh waveform · chấm điểm phát âm · backend API · offline cache · thông báo nhắc streak.

(Giọng đọc mẫu đã làm ở v1 dưới dạng audio render sẵn — xem 2.4. Phần TTS sinh
lúc chạy vẫn để v2 nếu cần nội dung động.)

Hai thứ cần làm đúng **ngay từ v1** để v2 không phải viết lại:
- `body` tách sẵn theo câu → v2 ghi âm và chấm điểm theo từng câu.
- `ContentRepository` là interface → v2 thay data source, UI giữ nguyên.
