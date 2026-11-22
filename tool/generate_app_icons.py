"""Generate Android and iOS launcher icon assets from assets/branding SVGs.

Requires Pillow and the librsvg `rsvg-convert` executable.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"


def render_svg(source: Path, output: Path, size: int) -> None:
    subprocess.run(
        [
            "rsvg-convert",
            "-w",
            str(size),
            "-h",
            str(size),
            "-o",
            str(output),
            str(source),
        ],
        check=True,
    )


def save_square(image: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(
        destination, optimize=True
    )


def main() -> None:
    if shutil.which("rsvg-convert") is None:
        raise SystemExit("Install librsvg so `rsvg-convert` is available.")

    with tempfile.TemporaryDirectory(prefix="chilli-app-icon-") as temporary:
        temporary_path = Path(temporary)
        icon_render = temporary_path / "app_icon.png"
        foreground_render = temporary_path / "app_icon_foreground.png"
        render_svg(BRANDING / "app_icon.svg", icon_render, 1024)
        render_svg(BRANDING / "app_icon_foreground.svg", foreground_render, 432)

        icon = Image.open(icon_render).convert("RGB")
        foreground = Image.open(foreground_render).convert("RGBA")

        icon.save(BRANDING / "app_icon.png", optimize=True)
        foreground_path = (
            ROOT
            / "android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png"
        )
        foreground_path.parent.mkdir(parents=True, exist_ok=True)
        foreground.save(foreground_path, optimize=True)

        for density, pixels in (
            ("mdpi", 48),
            ("hdpi", 72),
            ("xhdpi", 96),
            ("xxhdpi", 144),
            ("xxxhdpi", 192),
        ):
            save_square(
                icon,
                ROOT
                / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png",
                pixels,
            )

        contents_path = (
            ROOT
            / "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
        )
        contents = json.loads(contents_path.read_text(encoding="utf-8"))
        for item in contents["images"]:
            logical_size = float(item["size"].split("x", maxsplit=1)[0])
            scale = float(item["scale"].removesuffix("x"))
            pixels = round(logical_size * scale)
            save_square(icon, contents_path.parent / item["filename"], pixels)


if __name__ == "__main__":
    main()
