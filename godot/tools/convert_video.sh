#!/usr/bin/env bash
#
# Convert the game's MP4/MOV masters to Ogg Theora (.ogv).
#
# Godot 4's VideoStreamPlayer supports exactly one container: Ogg Theora.
# H.264/MP4 and QuickTime .MOV cannot be imported at all — the editor will not
# even list them. Run this once from the repo root:
#
#     ./godot/tools/convert_video.sh
#
# Requires ffmpeg with libtheora + libvorbis:
#     macOS    brew install ffmpeg
#     Ubuntu   sudo apt install ffmpeg
#     Windows  winget install Gyan.FFmpeg   (or use WSL)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$REPO_ROOT/godot/assets/video"

if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "error: ffmpeg not found on PATH. See the header of this script." >&2
	exit 1
fi

mkdir -p "$OUT_DIR"

# Quality scale: -q:v 0-10 for video, -q:a 0-10 for audio. 7/5 keeps these short
# clips visually clean at a reasonable size; drop -q:v to 5 if size matters more.
convert() {
	local src="$1" dest="$2" extra="${3:-}"
	if [[ ! -f "$src" ]]; then
		echo "skip: $src not found"
		return
	fi
	echo "==> $(basename "$src")  ->  $(basename "$dest")"
	# shellcheck disable=SC2086
	ffmpeg -hide_banner -loglevel warning -y -i "$src" \
		-c:v libtheora -q:v 7 \
		-c:a libvorbis -q:a 5 \
		$extra "$dest"
}

# Menu tower loop. It is muted in the web build (autoplay loop muted), so strip
# the audio track entirely — smaller file, and no chance of a stray sound.
convert "$REPO_ROOT/Tower Menu Animation 1400.mp4" \
	"$OUT_DIR/tower_menu_animation.ogv" "-an"

# Victory cinematic. Present in the repo but not wired up in the web build;
# converted here so it is ready if you use it on the victory screen.
convert "$REPO_ROOT/winning cinematic.mp4" \
	"$OUT_DIR/winning_cinematic.ogv"

echo
echo "Done. Output in godot/assets/video/"
ls -lh "$OUT_DIR"/*.ogv 2>/dev/null || true
echo
echo "Next: switch to the Godot editor so it detects and imports the new files."
