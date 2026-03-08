# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pillow",
# ]
# ///

"""Resize and convert project images to WebP format."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT
DEST = ROOT / "images"

IMAGES = {
    "zigzaglogo.png": {
        "name": "logo.webp",
        "max_size": 512,  # square logo
    },
    "socrates.png": {
        "name": "socrates.webp",
        "max_size": 400,  # small enough for margin/callout use
    },
}


def resize(src: Path, dest: Path, max_size: int) -> None:
    img = Image.open(src)
    img.thumbnail((max_size, max_size), Image.LANCZOS)
    img.save(dest, "WEBP", quality=85)

    src_kb = src.stat().st_size / 1024
    dest_kb = dest.stat().st_size / 1024
    print(f"  {src.name}: {src_kb:.0f} KB ({img.size[0]}x{img.size[1]})")
    print(f"  -> {dest.name}: {dest_kb:.0f} KB")


def main() -> None:
    DEST.mkdir(exist_ok=True)

    for filename, opts in IMAGES.items():
        src = SRC / filename
        if not src.exists():
            print(f"  SKIP {filename} (not found)")
            continue
        dest = DEST / opts["name"]
        resize(src, dest, opts["max_size"])

    print("\nDone. You can delete the original PNGs from the root directory.")


if __name__ == "__main__":
    main()
