# Design tokens

Trích từ mockup. **Đọc file này trước khi viết bất kỳ Composable nào.**
Không hardcode hex, dp, sp trong màn hình — chỉ dùng token ở đây.

## Nguyên tắc

- Nền **giấy ấm**, không trắng tinh. Chữ đen to trên nền trắng 100% gây chói khi đọc liên tục vài phút.
- Bốn màu nhấn có cùng độ đậm, mỗi màu có một việc riêng — đừng dùng lẫn.
- **Màu gắn với topic.** Thêm topic mới = thêm một token màu, không phải design lại màn hình.

## Màu

### Nền & chữ

| Token | Hex | Dùng cho |
|---|---|---|
| `paper` | `#FBF8F3` | nền màn hình |
| `surface` | `#FFFFFF` | thẻ, list item, bottom sheet |
| `surfaceMuted` | `#F2EDE4` | nền segmented control, ô số thứ tự |
| `border` | `#E8E2D8` | viền thẻ |
| `borderSubtle` | `#F0EBE2` | đường kẻ giữa các dòng trong một thẻ |
| `ink` | `#1A1726` | chữ chính |
| `inkMuted` | `#6B6579` | chữ phụ, caption, icon không active |
| `inkFaint` | `#A8A2B2` | mũi tên chevron |

### Màu nhấn

| Token | Hex | Tint nền | Chữ trên tint | Dùng cho |
|---|---|---|---|---|
| `violet` | `#5B4BD8` | `#EFECFC` | `#3A2DA8` | **hành động chính**: card đang dở, nút play, nút Áp dụng, tab active, filter đang chọn |
| `clay` | `#B8471F` | `#FDEAE2` | `#8A5A45` | topic Daily Life, bookmark, câu đang đọc trong Player |
| `teal` | `#0F7566` | `#DFF1EE` | `#3C6D64` | topic Business |
| `amber` | `#96661A` | `#FBEFD6` | `#7A5314` | streak, thành tích |
| `rose` | `#C2185B` | `#FCE7EF` | `#8E1044` | dự phòng cho topic thứ 5 |

Viền của thẻ tint dùng phiên bản đậm hơn tint một bậc: clay `#F6D6C8`, teal `#C4E4DE`, amber `#F0DDB4`, violet `#DAD4F7`.

Chữ trắng chỉ đặt trên `violet`. **Không** đặt chữ nhỏ màu trắng trên `clay` / `amber` — không đủ tương phản.

## Typography

| Vai trò | Font | Size / Weight |
|---|---|---|
| Display (tên màn, tên chủ đề, số stat) | **Bricolage Grotesque** 800, letter-spacing `-0.02em` | 22–27sp |
| Body / UI | **Manrope** 400 / 600 / 700 | 11–17sp |
| Text luyện tập | Manrope 700 | **20–40sp, người dùng chỉnh** — mặc định 29sp, line-height 1.32 |

Fallback: `system-ui` / `sans-serif`. Nhớ bundle 2 font vào `res/font/`.

Text luyện tập **căn giữa**. Chế độ cuộn đều: mọi câu cùng màu `ink`, alpha `1.0`,
không tô nền và không đánh dấu câu đang đọc — chỉ có chuyển động cuộn.
Hai chế độ còn lại (line, karaoke) vẫn highlight theo màu topic.

## Spacing

Thang 4dp. Hay dùng: `4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 22 · 28`.

- Padding màn hình: `20dp` ngang, `28dp` trên, `20dp` dưới
- Khoảng cách giữa các khối lớn: `18dp`
- Padding trong thẻ: `14dp` (list item) / `16–18dp` (thẻ lớn)
- Gap trong lưới: `12dp`

## Radius

| Token | dp | Dùng cho |
|---|---|---|
| `radiusSm` | 7 | badge, chip nhỏ |
| `radiusMd` | 12–14 | ô icon, nút trong sheet |
| `radiusLg` | 18 | list item, thẻ chủ đề |
| `radiusXl` | 20–22 | thẻ lớn, bottom nav |
| `radiusSheet` | 28 (chỉ 2 góc trên) | bottom sheet |
| `pill` | 50% | chip tốc độ, nút tròn, avatar |

## Kích thước chạm

- Mọi phần tử bấm được: **tối thiểu 44dp**
- Nút play chính: 72dp
- Nút tua: 48dp
- Icon button phụ: 44dp
- Bottom nav item: cao 50dp

## Chưa có

Bản này chỉ có **light theme**. Nếu làm dark theme sau, chỉ cần thêm bộ giá trị thứ hai cho chính các token trên — với điều kiện màn hình không hardcode hex. Đó là lý do có file này.
