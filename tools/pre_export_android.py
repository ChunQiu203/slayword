#!/usr/bin/env python3
"""
Pre-export script: copies external/ files into the Android assets directory
so they are bundled directly into the APK (bypassing Godot's PCK system).

Without this, Godot's export_filter="all_resources" misses files from
the external/ directory because .json files have no .import files and
the directory originally had a .gdignore marker.

Run this BEFORE each Android export from the Godot editor.
"""

import os
import shutil
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXTERNAL_DIR = os.path.join(PROJECT_ROOT, "external")
ANDROID_ASSETS = os.path.join(PROJECT_ROOT, "android", "build", "src", "main", "assets")
ANDROID_EXTERNAL = os.path.join(ANDROID_ASSETS, "external")

# Files/directories to EXCLUDE from the copy (runtime-generated, user data)
EXCLUDE_PATTERNS = {
    ".gdignore",
    "profile.json",
    "user_settings.json",
    "saves",
    "mods",
    "__pycache__",
    ".DS_Store",
}

# Optional: exclude AI-generated card art (~200 MB of ~500KB PNGs each).
# Card FRAMES and ICONS are still included. Set to False if you want ALL images.
SKIP_GENERATED_CARD_ART = True

def should_exclude(name: str) -> bool:
    if name in EXCLUDE_PATTERNS or name.startswith("."):
        return True
    if SKIP_GENERATED_CARD_ART and name == "generated":
        return True
    return False


def copy_tree(src: str, dst: str) -> tuple[int, int]:
    """Recursively copy src to dst. Returns (files_copied, dirs_created)."""
    files_copied = 0
    dirs_created = 0

    if not os.path.exists(src):
        print(f"  WARNING: source not found: {src}")
        return 0, 0

    for root, dirs, files in os.walk(src):
        # Filter out excluded directories in-place
        dirs[:] = [d for d in dirs if not should_exclude(d)]

        rel_path = os.path.relpath(root, src)
        if rel_path == ".":
            dst_dir = dst
        else:
            dst_dir = os.path.join(dst, rel_path)

        os.makedirs(dst_dir, exist_ok=True)
        dirs_created += 1

        for fname in files:
            if should_exclude(fname):
                continue
            src_file = os.path.join(root, fname)
            dst_file = os.path.join(dst_dir, fname)

            # Only copy if source is newer (idempotent)
            if os.path.exists(dst_file):
                src_mtime = os.path.getmtime(src_file)
                dst_mtime = os.path.getmtime(dst_file)
                if dst_mtime >= src_mtime:
                    continue

            shutil.copy2(src_file, dst_file)
            files_copied += 1

    return files_copied, dirs_created


def clean_android_external():
    """Remove stale files from the android assets external/ directory."""
    if not os.path.exists(ANDROID_EXTERNAL):
        return
    print(f"Cleaning: {ANDROID_EXTERNAL}")
    shutil.rmtree(ANDROID_EXTERNAL)


def main():
    print("=" * 60)
    print("Slayword Android Pre-Export: Bundling external/ files")
    print("=" * 60)

    if not os.path.exists(EXTERNAL_DIR):
        print(f"ERROR: external/ directory not found at: {EXTERNAL_DIR}")
        sys.exit(1)

    if not os.path.exists(ANDROID_ASSETS):
        print(f"Creating assets directory: {ANDROID_ASSETS}")
        os.makedirs(ANDROID_ASSETS, exist_ok=True)

    # Clean old copy
    clean_android_external()

    # Copy fresh
    print(f"\nCopying: {EXTERNAL_DIR}")
    print(f"      -> {ANDROID_EXTERNAL}")
    files_copied, dirs_created = copy_tree(EXTERNAL_DIR, ANDROID_EXTERNAL)

    print(f"\nDone: {files_copied} files copied, {dirs_created} directories created")

    # Report what was included
    total_size = 0
    for root, dirs, files in os.walk(ANDROID_EXTERNAL):
        for f in files:
            total_size += os.path.getsize(os.path.join(root, f))
    print(f"Total bundled size: {total_size / 1024:.1f} KB ({total_size / 1024 / 1024:.2f} MB)")
    print("=" * 60)


if __name__ == "__main__":
    main()
