#!/usr/bin/env python3
"""
Optional: Compress AI-generated card art for mobile distribution.
Reduces ~200 MB (198 files @ ~1 MB each) to ~15-25 MB.

Run BEFORE exporting from Godot:
    python tools/optimize_card_art.py

The script resizes images to a max of 512px (mobile screen appropriate)
and applies PNG optimization. Original files are backed up to *_original.png.
"""

import os
import sys
from PIL import Image

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GENERATED_DIR = os.path.join(PROJECT_ROOT, "external", "sprites", "cards", "generated")

# Settings
MAX_SIZE = 512  # max width/height in pixels
QUALITY = 85    # PNG compression level (not WebP)


def optimize_image(filepath: str) -> tuple[int, int]:
    """Resize and compress a PNG. Returns (old_size, new_size)."""
    old_size = os.path.getsize(filepath)

    img = Image.open(filepath)
    w, h = img.width, img.height

    # Resize if needed
    if w > MAX_SIZE or h > MAX_SIZE:
        img.thumbnail((MAX_SIZE, MAX_SIZE), Image.LANCZOS)

    # Backup original if resized
    backup = filepath.replace(".png", "_original.png")
    needs_backup = (w > MAX_SIZE or h > MAX_SIZE)
    if needs_backup and not os.path.exists(backup):
        os.rename(filepath, backup)
        img = Image.open(backup)
        img.thumbnail((MAX_SIZE, MAX_SIZE), Image.LANCZOS)

    # Always save with optimization (strip metadata, compress better)
    img.save(filepath, "PNG", optimize=True)

    new_size = os.path.getsize(filepath)
    return old_size, new_size


def main():
    if not os.path.exists(GENERATED_DIR):
        print(f"ERROR: {GENERATED_DIR} not found")
        sys.exit(1)

    png_files = [f for f in os.listdir(GENERATED_DIR) if f.endswith(".png") and "_original" not in f]
    print(f"Found {len(png_files)} card art images in generated/")
    print(f"Max dimension: {MAX_SIZE}px")
    print()

    total_before = 0
    total_after = 0
    optimized = 0

    for fname in sorted(png_files):
        filepath = os.path.join(GENERATED_DIR, fname)
        old, new = optimize_image(filepath)
        total_before += old
        total_after += new
        if old != new:
            optimized += 1
            pct = 100 * (old - new) / old
            print(f"  {fname}: {old/1024:.0f}K -> {new/1024:.0f}K ({pct:.0f}% saved)")

    print()
    print(f"Optimized: {optimized}/{len(png_files)} files")
    print(f"Before: {total_before/1024/1024:.1f} MB")
    print(f"After:  {total_after/1024/1024:.1f} MB")
    print(f"Saved:  {(total_before-total_after)/1024/1024:.1f} MB ({(100*(total_before-total_after)/total_before):.0f}%)")


if __name__ == "__main__":
    main()
