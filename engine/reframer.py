#!/usr/bin/env python3
"""VIDMARK STUDIO Reframer.

Local, zero-cost 16:9-to-vertical reframing for video masters.
Uses FFmpeg for media IO/export and Pillow for lightweight frame analysis.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import statistics
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable, Optional

from PIL import Image, ImageChops, ImageFilter


DEFAULT_WIDTH = 1080
DEFAULT_HEIGHT = 1920


@dataclass
class MediaInfo:
    path: str
    width: int
    height: int
    duration: float
    fps: float
    has_audio: bool


@dataclass
class FrameSignal:
    t: float
    motion_score: float
    edge_score: float
    focus_x: float
    score: float
    scene_cut: bool = False


@dataclass
class Candidate:
    index: int
    start: float
    duration: float
    end: float
    score: float
    opening_score: float
    crop_x: int
    crop_y: int
    crop_w: int
    crop_h: int
    focus_x: float
    confidence: float
    output: str
    mode: str


def fail(message: str, code: int = 2) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def find_binary(name: str) -> str:
    found = shutil.which(name)
    if found:
        return found
    for prefix in ("/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"):
        candidate = Path(prefix) / name
        if candidate.exists():
            return str(candidate)
    fail(f"{name} not found. Install FFmpeg or add it to PATH.")


FFMPEG = find_binary("ffmpeg")
FFPROBE = find_binary("ffprobe")


def run(cmd: list[str], *, capture: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def parse_ratio(value: str) -> tuple[int, int]:
    raw = value.strip().lower().replace("x", ":")
    if ":" not in raw:
        fail("Aspect ratio must look like 9:16, 4:5, 1:1, or 16:9.")
    left, right = raw.split(":", 1)
    try:
        w = int(left)
        h = int(right)
    except ValueError:
        fail("Aspect ratio must use whole numbers, like 9:16.")
    if w <= 0 or h <= 0:
        fail("Aspect ratio values must be positive.")
    return w, h


def media_info(input_path: Path) -> MediaInfo:
    cmd = [
        FFPROBE,
        "-v",
        "error",
        "-show_entries",
        "format=duration:stream=index,codec_type,width,height,avg_frame_rate,r_frame_rate",
        "-of",
        "json",
        str(input_path),
    ]
    data = json.loads(run(cmd).stdout)
    streams = data.get("streams", [])
    video = next((s for s in streams if s.get("codec_type") == "video"), None)
    if not video:
        fail(f"No video stream found in {input_path}")
    has_audio = any(s.get("codec_type") == "audio" for s in streams)
    duration = float(data.get("format", {}).get("duration") or 0)
    if duration <= 0:
        fail("Could not determine video duration.")
    fps_text = video.get("avg_frame_rate") or video.get("r_frame_rate") or "24/1"
    fps = parse_fps(fps_text)
    return MediaInfo(
        path=str(input_path),
        width=int(video["width"]),
        height=int(video["height"]),
        duration=duration,
        fps=fps,
        has_audio=has_audio,
    )


def parse_fps(value: str) -> float:
    if "/" in value:
        n, d = value.split("/", 1)
        try:
            denom = float(d)
            return float(n) / denom if denom else 24.0
        except ValueError:
            return 24.0
    try:
        return float(value)
    except ValueError:
        return 24.0


def infer_project_dir(input_path: Path) -> Path:
    for parent in [input_path.parent, *input_path.parents]:
        if parent.name.startswith(("VID-", "VRS-")):
            return parent
    return input_path.parent


def infer_output_dir(input_path: Path) -> Path:
    return infer_project_dir(input_path) / "shorts" / "reframer-candidates"


def crop_geometry(width: int, height: int, ratio: tuple[int, int], focus_x: float, mode: str) -> tuple[int, int, int, int]:
    ratio_w, ratio_h = ratio
    target_aspect = ratio_w / ratio_h
    source_aspect = width / height
    if source_aspect >= target_aspect:
        crop_h = height
        crop_w = int(round(height * target_aspect))
    else:
        crop_w = width
        crop_h = int(round(width / target_aspect))
    crop_w = min(width, max(2, even(crop_w)))
    crop_h = min(height, max(2, even(crop_h)))
    if mode == "center":
        center_x = width / 2
    else:
        center_x = focus_x * width
    crop_x = int(round(center_x - crop_w / 2))
    crop_x = max(0, min(width - crop_w, crop_x))
    crop_y = max(0, int(round((height - crop_h) / 2)))
    return even(crop_x), even(crop_y), crop_w, crop_h


def even(value: int) -> int:
    return value if value % 2 == 0 else value - 1


def sample_frames(input_path: Path, info: MediaInfo, sample_fps: float, analysis_width: int) -> list[FrameSignal]:
    analysis_width = max(120, min(640, analysis_width))
    scale = f"scale={analysis_width}:-2"
    cmd = [
        FFMPEG,
        "-v",
        "error",
        "-i",
        str(input_path),
        "-vf",
        f"fps={sample_fps},{scale}",
        "-pix_fmt",
        "rgb24",
        "-f",
        "rawvideo",
        "-",
    ]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if not proc.stdout:
        fail("Could not read sampled frames.")

    sample_h = even(int(round(analysis_width * info.height / info.width)))
    frame_size = analysis_width * sample_h * 3
    signals: list[FrameSignal] = []
    previous_gray: Optional[Image.Image] = None
    index = 0
    while True:
        chunk = proc.stdout.read(frame_size)
        if not chunk:
            break
        if len(chunk) != frame_size:
            break
        frame = Image.frombytes("RGB", (analysis_width, sample_h), chunk)
        gray = frame.convert("L")
        edge_x, edge_score = weighted_x(gray.filter(ImageFilter.FIND_EDGES))
        motion_x = edge_x
        motion_score = 0.0
        if previous_gray is not None:
            diff = ImageChops.difference(gray, previous_gray)
            motion_x, motion_score = weighted_x(diff)
        focus_x = blend_focus(edge_x, edge_score, motion_x, motion_score)
        score = motion_score * 0.72 + edge_score * 0.28
        signals.append(
            FrameSignal(
                t=index / sample_fps,
                motion_score=round(motion_score, 6),
                edge_score=round(edge_score, 6),
                focus_x=round(focus_x, 6),
                score=round(score, 6),
            )
        )
        previous_gray = gray
        index += 1
    stderr = proc.stderr.read().decode("utf-8", errors="replace") if proc.stderr else ""
    return_code = proc.wait()
    if return_code != 0:
        fail(f"FFmpeg frame sampling failed: {stderr.strip()}")
    if not signals:
        fail("No frames sampled from source video.")
    mark_scene_cuts(signals)
    return signals


def weighted_x(image: Image.Image) -> tuple[float, float]:
    # Downsample once more for speed, then compute a weighted x centroid.
    max_w = 240
    if image.width > max_w:
        h = max(2, int(round(image.height * max_w / image.width)))
        image = image.resize((max_w, h))
    pixels = image.load()
    total = 0.0
    x_total = 0.0
    width, height = image.size
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            value = pixels[x, y]
            if value < 8:
                continue
            weight = float(value)
            total += weight
            x_total += weight * x
    if total <= 0:
        return 0.5, 0.0
    focus_x = x_total / total / max(1, width - 1)
    score = min(1.0, total / ((width // 2 + 1) * (height // 2 + 1) * 64.0))
    return clamp(focus_x, 0.0, 1.0), score


def blend_focus(edge_x: float, edge_score: float, motion_x: float, motion_score: float) -> float:
    edge_w = max(edge_score, 0.02)
    motion_w = motion_score * 2.5
    if motion_w + edge_w <= 0:
        return 0.5
    focus = (motion_x * motion_w + edge_x * edge_w) / (motion_w + edge_w)
    # Pull gently toward center so the result stays stable and less seasick.
    return clamp(focus * 0.82 + 0.5 * 0.18, 0.0, 1.0)


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def mark_scene_cuts(signals: list[FrameSignal]) -> None:
    if len(signals) < 4:
        return
    motion = [s.motion_score for s in signals[1:]]
    mean = statistics.mean(motion)
    stdev = statistics.pstdev(motion) if len(motion) > 1 else 0.0
    threshold = max(mean + stdev * 2.4, mean * 2.5, 0.045)
    last_cut = -99.0
    for signal in signals[1:]:
        if signal.motion_score >= threshold and signal.t - last_cut >= 1.2:
            signal.scene_cut = True
            last_cut = signal.t


def choose_candidates(
    signals: list[FrameSignal],
    info: MediaInfo,
    ratio: tuple[int, int],
    mode: str,
    target_duration: float,
    candidate_count: int,
) -> list[Candidate]:
    if info.duration <= target_duration:
        windows = [(0.0, max(0.1, info.duration))]
    else:
        step = max(2.0, target_duration / 4)
        min_candidate_duration = min(target_duration, max(4.0, target_duration * 0.75))
        windows = []
        start = 0.0
        while start + min_candidate_duration <= info.duration + 0.05:
            duration = min(target_duration, info.duration - start)
            if duration >= min_candidate_duration:
                windows.append((start, duration))
            start += step
    scored: list[tuple[float, float, float, float, float]] = []
    for start, duration in windows:
        end = start + duration
        frame_slice = [s for s in signals if start <= s.t <= end]
        if not frame_slice:
            continue
        opening = [s for s in frame_slice if s.t <= start + min(3.0, duration)]
        avg_score = statistics.mean(s.score for s in frame_slice)
        opening_score = statistics.mean(s.score for s in opening) if opening else avg_score
        focus_x = weighted_focus(frame_slice)
        stability = 1.0 - min(1.0, statistics.pstdev(s.focus_x for s in frame_slice) * 3.0) if len(frame_slice) > 1 else 0.7
        scene_bonus = min(0.12, sum(1 for s in frame_slice if s.scene_cut) * 0.025)
        final_score = avg_score * 0.58 + opening_score * 0.28 + stability * 0.14 + scene_bonus
        confidence = clamp(avg_score * 0.65 + opening_score * 0.25 + stability * 0.10, 0.0, 1.0)
        scored.append((final_score, start, duration, focus_x, confidence))

    scored.sort(key=lambda item: item[0], reverse=True)
    selected: list[Candidate] = []
    for final_score, start, duration, focus_x, confidence in scored:
        if any(overlap(start, start + duration, c.start, c.end) > duration * 0.55 for c in selected):
            continue
        crop_x, crop_y, crop_w, crop_h = crop_geometry(info.width, info.height, ratio, focus_x, mode)
        selected.append(
            Candidate(
                index=len(selected) + 1,
                start=round(start, 3),
                duration=round(duration, 3),
                end=round(start + duration, 3),
                score=round(final_score, 6),
                opening_score=round(score_window(signals, start, min(start + 3.0, start + duration)), 6),
                crop_x=crop_x,
                crop_y=crop_y,
                crop_w=crop_w,
                crop_h=crop_h,
                focus_x=round(focus_x, 6),
                confidence=round(confidence, 6),
                output="",
                mode=mode,
            )
        )
        if len(selected) >= candidate_count:
            break
    if not selected:
        focus_x = 0.5
        crop_x, crop_y, crop_w, crop_h = crop_geometry(info.width, info.height, ratio, focus_x, mode)
        selected.append(
            Candidate(
                index=1,
                start=0.0,
                duration=round(min(target_duration, info.duration), 3),
                end=round(min(target_duration, info.duration), 3),
                score=0.0,
                opening_score=0.0,
                crop_x=crop_x,
                crop_y=crop_y,
                crop_w=crop_w,
                crop_h=crop_h,
                focus_x=0.5,
                confidence=0.0,
                output="",
                mode=mode,
            )
        )
    return selected


def weighted_focus(signals: Iterable[FrameSignal]) -> float:
    total = 0.0
    x_total = 0.0
    for signal in signals:
        weight = max(0.025, signal.score)
        total += weight
        x_total += signal.focus_x * weight
    if total <= 0:
        return 0.5
    return clamp(x_total / total, 0.0, 1.0)


def score_window(signals: list[FrameSignal], start: float, end: float) -> float:
    values = [s.score for s in signals if start <= s.t <= end]
    return statistics.mean(values) if values else 0.0


def overlap(a1: float, a2: float, b1: float, b2: float) -> float:
    return max(0.0, min(a2, b2) - max(a1, b1))


def quality_settings(name: str) -> tuple[str, str]:
    presets = {
        "draft": ("24", "veryfast"),
        "standard": ("20", "medium"),
        "high": ("17", "slow"),
        "archival": ("14", "slower"),
    }
    return presets.get(name, presets["standard"])


def export_candidate(
    input_path: Path,
    output_dir: Path,
    slug: str,
    candidate: Candidate,
    out_w: int,
    out_h: int,
    quality: str,
) -> Candidate:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{slug}_short-candidate-{candidate.index:02d}_{candidate.mode}_{out_w}x{out_h}.mp4"
    crf, preset = quality_settings(quality)
    vf = (
        f"crop={candidate.crop_w}:{candidate.crop_h}:{candidate.crop_x}:{candidate.crop_y},"
        f"scale={out_w}:{out_h}:flags=lanczos,setsar=1"
    )
    cmd = [
        FFMPEG,
        "-y",
        "-ss",
        f"{candidate.start:.3f}",
        "-i",
        str(input_path),
        "-t",
        f"{candidate.duration:.3f}",
        "-map",
        "0:v:0",
        "-map",
        "0:a?",
        "-vf",
        vf,
        "-c:v",
        "libx264",
        "-preset",
        preset,
        "-crf",
        crf,
        "-c:a",
        "aac",
        "-b:a",
        "160k",
        "-movflags",
        "+faststart",
        str(output_path),
    ]
    run(cmd)
    candidate.output = str(output_path)
    return candidate


def write_reports(
    output_dir: Path,
    slug: str,
    info: MediaInfo,
    candidates: list[Candidate],
    args: argparse.Namespace,
    source_video: Path,
    signals: list[FrameSignal],
) -> tuple[Path, Path]:
    report = {
        "tool": "VIDMARK STUDIO Reframer",
        "version": "0.1.0",
        "source_video": str(source_video),
        "source": asdict(info),
        "settings": {
            "mode": args.mode,
            "aspect": args.aspect,
            "width": args.width,
            "height": args.height,
            "duration": args.duration,
            "candidates": args.candidates,
            "quality": args.quality,
            "sample_fps": args.sample_fps,
            "analysis_width": args.analysis_width,
        },
        "scene_cuts_detected": [round(s.t, 3) for s in signals if s.scene_cut],
        "cost": {
            "local_tool_cost_usd": 0,
            "paid_services_used": [],
            "notes": "Local FFmpeg/Pillow analysis and export. No paid service used.",
        },
        "candidates": [asdict(c) for c in candidates],
    }
    json_path = output_dir / f"{slug}_reframe-report.json"
    md_path = output_dir / f"{slug}_reframe-report.md"
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = [
        f"# Reframe Report: {slug}",
        "",
        f"- Source: `{source_video}`",
        f"- Source size: `{info.width}x{info.height}`",
        f"- Source duration: `{info.duration:.2f}s`",
        f"- Mode: `{args.mode}`",
        f"- Output: `{args.width}x{args.height}` / aspect `{args.aspect}`",
        f"- Quality: `{args.quality}`",
        "- Cost: `$0 local`",
        f"- Scene cuts detected: `{len(report['scene_cuts_detected'])}`",
        "",
        "## Candidates",
        "",
        "| # | Start | Duration | Crop | Confidence | Output |",
        "| --- | ---: | ---: | --- | ---: | --- |",
    ]
    for c in candidates:
        output = c.output or "plan only"
        lines.append(
            f"| {c.index} | {c.start:.2f}s | {c.duration:.2f}s | "
            f"`{c.crop_w}x{c.crop_h}+{c.crop_x}+{c.crop_y}` | {c.confidence:.2f} | `{output}` |"
        )
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return json_path, md_path


def slug_from_path(input_path: Path) -> str:
    project_dir = infer_project_dir(input_path)
    if project_dir.name.startswith(("VID-", "VRS-")):
        return project_dir.name
    return input_path.stem.replace(" ", "-")


def normalize_output_size(width: int, height: int) -> tuple[int, int]:
    if width <= 0 or height <= 0:
        fail("Output width and height must be positive.")
    return even(width), even(height)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create vertical short candidates from a widescreen video master.")
    parser.add_argument("input", help="Source video file. 1080p and 4K masters are supported.")
    parser.add_argument("--output-dir", default="", help="Output directory. Defaults to <video project>/shorts/reframer-candidates.")
    parser.add_argument("--mode", choices=["smart", "center", "plan-only"], default="smart")
    parser.add_argument("--aspect", default="9:16", help="Target aspect ratio, e.g. 9:16, 4:5, 1:1.")
    parser.add_argument("--width", type=int, default=DEFAULT_WIDTH, help="Output width in pixels.")
    parser.add_argument("--height", type=int, default=DEFAULT_HEIGHT, help="Output height in pixels.")
    parser.add_argument("--duration", type=float, default=20.0, help="Target candidate duration in seconds.")
    parser.add_argument("--candidates", type=int, default=3, help="Number of candidates to export.")
    parser.add_argument("--quality", choices=["draft", "standard", "high", "archival"], default="standard")
    parser.add_argument("--sample-fps", type=float, default=2.0, help="Analysis sampling rate.")
    parser.add_argument("--analysis-width", type=int, default=320, help="Low-res analysis width.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    if not input_path.exists():
        fail(f"Input video not found: {input_path}")
    ratio = parse_ratio(args.aspect)
    args.width, args.height = normalize_output_size(args.width, args.height)
    if args.duration < 4:
        fail("Duration should be at least 4 seconds.")
    args.candidates = max(1, min(12, args.candidates))
    output_dir = Path(args.output_dir).expanduser().resolve() if args.output_dir else infer_output_dir(input_path)
    slug = slug_from_path(input_path)

    print(f"Analyzing {input_path.name}...")
    info = media_info(input_path)
    print(f"Source: {info.width}x{info.height}, {info.duration:.2f}s, audio={info.has_audio}")
    signals = sample_frames(input_path, info, args.sample_fps, args.analysis_width)
    framing_mode = "center" if args.mode == "center" else "smart"
    candidates = choose_candidates(signals, info, ratio, framing_mode, args.duration, args.candidates)

    if args.mode != "plan-only":
        for candidate in candidates:
            print(f"Exporting candidate {candidate.index}: {candidate.start:.2f}s for {candidate.duration:.2f}s...")
            export_candidate(input_path, output_dir, slug, candidate, args.width, args.height, args.quality)

    json_path, md_path = write_reports(output_dir, slug, info, candidates, args, input_path, signals)
    print(f"Report: {md_path}")
    print(f"JSON: {json_path}")
    print("Done. Cost: $0 local.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
