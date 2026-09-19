#!/usr/bin/env python3
"""Render giọng đọc mẫu cho chế độ VOICE bằng Kokoro (chạy local, offline).

Mỗi câu được tổng hợp riêng rồi mới ghép, nên độ dài từng câu suy ra chính xác
từ số mẫu audio — không cần forced alignment, không cần ffmpeg.

Kokoro đọc rất nhanh (~200-250 wpm ở speed 1.0). Script tự dò tốc độ tổng hợp
để bài ra đúng `--target-wpm`, cố ý nhắm vào *đáy* dải wpm của chế độ đọc: lúc
phát, app chỉ việc tăng tốc, không bao giờ phải kéo chậm (kéo chậm méo tiếng
hơn nhiều).

Chuẩn bị (một lần):
    brew install espeak-ng
    python3 -m venv .venv && .venv/bin/pip install kokoro-onnx lameenc
    curl -L -o kokoro-v1.0.onnx https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx
    curl -L -o voices-v1.0.bin  https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin

Chạy:
    .venv/bin/python tool/generate_voice.py --voice am_michael
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent
PASSAGES_DIR = REPO / "assets" / "content" / "passages"
AUDIO_DIR = REPO / "assets" / "audio"
VOICE_DIR = REPO / "assets" / "content" / "voice"

SAMPLE_RATE = 24000
MP3_KBPS = 48

# Khoảng lặng chèn giữa hai câu. Người học cần một nhịp để bắt kịp câu sau;
# đây cũng chính là khoảng hở giữa hai câu trong bảng timing.
SENTENCE_GAP_SEC = 0.35


def load_kokoro(model: Path, voices: Path):
    # Bản espeak-ng kèm trong wheel `espeakng-loader` nén cứng đường dẫn data
    # của máy build, nên phải trỏ sang bản cài bằng brew. Chỉ biến môi trường
    # có tác dụng, và phải đặt trước khi phonemizer được import.
    for data, lib in (
        ("/opt/homebrew/share/espeak-ng-data", "/opt/homebrew/lib/libespeak-ng.dylib"),
        ("/usr/local/share/espeak-ng-data", "/usr/local/lib/libespeak-ng.dylib"),
        ("/usr/share/espeak-ng-data", "/usr/lib/libespeak-ng.so"),
    ):
        if Path(data).exists() and Path(lib).exists():
            os.environ["ESPEAK_DATA_PATH"] = data
            os.environ["PHONEMIZER_ESPEAK_LIBRARY"] = lib
            break
    else:
        sys.exit("Không tìm thấy espeak-ng. Chạy: brew install espeak-ng")

    from kokoro_onnx import Kokoro

    return Kokoro(str(model), str(voices))


def read_passages() -> list[dict]:
    passages = []
    for path in sorted(PASSAGES_DIR.glob("*.json")):
        data = json.loads(path.read_text())
        passages.extend(data if isinstance(data, list) else data["passages"])
    return passages


def synth(kokoro, sentences: list[str], voice: str, speed: float):
    """Trả về (audio đã ghép, mốc đầu/cuối từng câu tính bằng ms)."""
    chunks: list[np.ndarray] = []
    spans: list[tuple[int, int]] = []
    gap = np.zeros(int(SAMPLE_RATE * SENTENCE_GAP_SEC), dtype=np.float32)
    cursor = 0

    for sentence in sentences:
        samples, rate = kokoro.create(sentence, voice=voice, speed=speed, lang="en-us")
        assert rate == SAMPLE_RATE, f"sample rate lạ: {rate}"
        samples = samples.astype(np.float32)
        start = cursor
        cursor += len(samples)
        spans.append((round(start / SAMPLE_RATE * 1000), round(cursor / SAMPLE_RATE * 1000)))
        chunks.append(samples)
        chunks.append(gap)
        cursor += len(gap)

    return np.concatenate(chunks), spans


def calibrate(kokoro, sentences: list[str], voice: str, target_wpm: int) -> float:
    """Dò tốc độ tổng hợp trên vài câu đầu để bài ra xấp xỉ `target_wpm`.

    Hai vòng: `speed` của Kokoro không tỉ lệ tuyến tính với tốc độ đọc thật,
    một vòng thường lệch hơn 10 wpm.
    """
    probe = sentences[: min(3, len(sentences))]
    words = sum(len(s.split()) for s in probe)

    def wpm_at(speed: float) -> float:
        _, spans = synth(kokoro, probe, voice, speed)
        speech_sec = sum(end - start for start, end in spans) / 1000
        return words / speech_sec * 60

    # Kokoro từ chối speed ngoài [0.5, 2.0].
    def clamp(value: float) -> float:
        return min(2.0, max(0.5, round(value, 2)))

    speed = clamp(target_wpm / wpm_at(1.0))
    if speed in (0.5, 2.0):
        return speed
    return clamp(speed * target_wpm / wpm_at(speed))


def encode_mp3(samples: np.ndarray, path: Path) -> int:
    import lameenc

    pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2")
    encoder = lameenc.Encoder()
    encoder.set_bit_rate(MP3_KBPS)
    encoder.set_in_sample_rate(SAMPLE_RATE)
    encoder.set_channels(1)
    encoder.set_quality(2)
    data = encoder.encode(pcm.tobytes()) + encoder.flush()
    path.write_bytes(data)
    return len(data)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", default="am_michael")
    parser.add_argument("--target-wpm", type=int, default=105)
    parser.add_argument("--model", type=Path, default=Path("kokoro-v1.0.onnx"))
    parser.add_argument("--voices", type=Path, default=Path("voices-v1.0.bin"))
    parser.add_argument("--only", help="chỉ render passage có id này")
    args = parser.parse_args()

    for path in (args.model, args.voices):
        if not path.exists():
            sys.exit(f"Thiếu {path} — xem hướng dẫn tải ở đầu file này.")

    kokoro = load_kokoro(args.model, args.voices)
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    VOICE_DIR.mkdir(parents=True, exist_ok=True)

    passages = read_passages()
    if args.only:
        passages = [p for p in passages if p["id"] == args.only]
        if not passages:
            sys.exit(f"Không có passage id {args.only}")

    total_bytes = 0
    for passage in passages:
        body = passage["body"]
        speed = calibrate(kokoro, body, args.voice, args.target_wpm)
        audio, spans = synth(kokoro, body, args.voice, speed)

        speech_sec = sum(end - start for start, end in spans) / 1000
        words = sum(len(s.split()) for s in body)
        native_wpm = round(words / speech_sec * 60)

        size = encode_mp3(audio, AUDIO_DIR / f"{passage['id']}.mp3")
        total_bytes += size

        (VOICE_DIR / f"{passage['id']}.json").write_text(
            json.dumps(
                {
                    "passageId": passage["id"],
                    "audio": f"assets/audio/{passage['id']}.mp3",
                    "voice": args.voice,
                    "nativeWpm": native_wpm,
                    "totalMs": round(len(audio) / SAMPLE_RATE * 1000),
                    "sentences": [
                        {"index": i, "startMs": s, "endMs": e}
                        for i, (s, e) in enumerate(spans)
                    ],
                },
                indent=2,
            )
            + "\n"
        )

        print(
            f"{passage['id']:16s} speed={speed:4.2f} wpm={native_wpm:4d} "
            f"{len(audio) / SAMPLE_RATE:6.1f}s {size / 1024:6.0f}KB"
        )

    print(f"\nTổng {len(passages)} bài, {total_bytes / 1024 / 1024:.1f}MB")


if __name__ == "__main__":
    main()
