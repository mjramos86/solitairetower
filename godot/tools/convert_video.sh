#!/usr/bin/env bash
#
# Convert the game's MP4/MOV masters to Ogg Theora (.ogv).
#
# Godot 4's VideoStreamPlayer supports exactly one container: Ogg Theora, with
# Theora video + Vorbis audio inside it. H.264/MP4 and QuickTime .MOV cannot be
# opened at all. Run this once from anywhere:
#
#     bash godot/tools/convert_video.sh
#
# Add --check to diagnose without converting (prints ffmpeg capabilities, source
# files found, and the status of anything already converted):
#
#     bash godot/tools/convert_video.sh --check
#
# Requires ffmpeg built with libtheora + libvorbis:
#     macOS    brew install ffmpeg
#     Ubuntu   sudo apt install ffmpeg
#     Windows  winget install Gyan.FFmpeg   (run from Git Bash, not PowerShell)
#
# Must run under bash: this uses BASH_SOURCE and [[ ]]. Running it with `sh` on a
# dash-based system resolves the wrong directory and would write the output where
# Godot never looks. This check has to come before `set -o pipefail`, which dash
# rejects outright with a far less helpful message.
if [ -z "${BASH_VERSION:-}" ]; then
	echo "error: run this with bash, not sh." >&2
	echo "       Use:  bash godot/tools/convert_video.sh" >&2
	exit 1
fi

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$REPO_ROOT/godot/assets/video"
CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1

fail=0

# ── Preflight ─────────────────────────────────────────────────────────────────
echo "repo root : $REPO_ROOT"
echo "output    : $OUT_DIR"
echo

if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "error: ffmpeg not found on PATH." >&2
	echo "       Install it (see the header of this script), reopen your terminal," >&2
	echo "       and run this again." >&2
	exit 1
fi
echo "ffmpeg    : $(ffmpeg -version 2>/dev/null | head -1)"

# A stock ffmpeg does not always ship the Theora/Vorbis encoders. Catching this
# up front is the difference between a clear message and an empty output folder.
missing_encoders=""
for enc in libtheora libvorbis; do
	if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep -qw "$enc"; then
		missing_encoders="$missing_encoders $enc"
	fi
done
if [[ -n "$missing_encoders" ]]; then
	echo >&2
	echo "error: your ffmpeg is missing:$missing_encoders" >&2
	echo "       Theora output is impossible without it. Install a full build:" >&2
	echo "         macOS    brew install ffmpeg" >&2
	echo "         Ubuntu   sudo apt install ffmpeg" >&2
	echo "         Windows  winget install Gyan.FFmpeg   (the 'full' build)" >&2
	exit 1
fi
echo "encoders  : libtheora, libvorbis present"
echo

mkdir -p "$OUT_DIR"

# ── Conversion ────────────────────────────────────────────────────────────────
# Quality scale: -q:v 0-10 for video, -q:a 0-10 for audio. 7/5 keeps these short
# clips visually clean at a reasonable size; drop -q:v to 5 if size matters more.
#
# -pix_fmt yuv420p is required: Theora supports no other pixel format, and a
# source in yuv444p or with an alpha channel will otherwise abort the encode.
convert() {
	local src="$1" dest="$2"
	shift 2
	local label
	label="$(basename "$dest")"

	if [[ ! -f "$src" ]]; then
		echo "SKIP  $label — source not found:"
		echo "        $src"
		fail=1
		return
	fi

	if [[ "$CHECK_ONLY" == "1" ]]; then
		echo "FOUND $(basename "$src")  ->  would write $label"
		return
	fi

	echo "==>   $(basename "$src")  ->  $label"
	if ! ffmpeg -hide_banner -loglevel error -y -i "$src" \
		-c:v libtheora -q:v 7 -pix_fmt yuv420p \
		-c:a libvorbis -q:a 5 \
		"$@" "$dest"; then
		echo "FAIL  $label — ffmpeg returned an error (see above)."
		fail=1
		return
	fi

	# ffmpeg can exit 0 having written a zero-byte or unreadable file.
	if [[ ! -s "$dest" ]]; then
		echo "FAIL  $label — output is missing or empty."
		fail=1
		return
	fi
	verify "$dest"
}

# Confirm the container really holds Theora. Godot rejects an .ogv whose video
# stream is anything else, and the failure mode is a silent non-detection.
verify() {
	local dest="$1" codec="" size=""
	size="$(du -h "$dest" | cut -f1)"
	if command -v ffprobe >/dev/null 2>&1; then
		codec="$(ffprobe -v error -select_streams v:0 \
			-show_entries stream=codec_name -of csv=p=0 "$dest" 2>/dev/null | tr -d '\r\n')"
		if [[ "$codec" != "theora" ]]; then
			echo "FAIL  $(basename "$dest") — video stream is '$codec', expected 'theora'."
			fail=1
			return
		fi
		echo "OK    $(basename "$dest")  ($size, theora)"
	else
		echo "OK    $(basename "$dest")  ($size, codec unverified — ffprobe not installed)"
	fi
}

# Menu tower loop. Muted in the web build (autoplay loop muted), so -an strips
# the audio track entirely: smaller file, no chance of a stray sound.
convert "$REPO_ROOT/Tower Menu Animation 1400.mp4" \
	"$OUT_DIR/tower_menu_animation.ogv" -an

# Victory cinematic. Present in the repo but not wired up in the web build;
# converted here so it is ready if you use it on the victory screen.
convert "$REPO_ROOT/winning cinematic.mp4" \
	"$OUT_DIR/winning_cinematic.ogv"

# ── Report ────────────────────────────────────────────────────────────────────
echo
echo "Contents of $OUT_DIR:"
if ls "$OUT_DIR"/*.ogv >/dev/null 2>&1; then
	ls -lh "$OUT_DIR"/*.ogv | sed 's/^/  /'
else
	echo "  (no .ogv files — nothing was produced)"
	fail=1
fi

echo
if [[ "$fail" != "0" ]]; then
	echo "Finished with problems — see FAIL/SKIP lines above."
	exit 1
fi

if [[ "$CHECK_ONLY" == "1" ]]; then
	echo "Check passed. Re-run without --check to convert."
	exit 0
fi

cat <<'NEXT'
Done. Now, in Godot:

  1. Switch to the Godot window. It rescans on focus and the files should
     appear under res://assets/video/ in the FileSystem dock.
  2. If they do not appear, use Project > Reload Current Project. That forces
     a full rescan and resolves almost every case.
  3. Note: .ogv files have NO "Import" tab. Godot loads video directly rather
     than importing it, so an absent Import tab is normal, not a failure.
     Clicking the file should show a VideoStreamTheora resource in the
     Inspector.
  4. Re-run the project (F5). The grey circles on the asset check screen turn
     green once the files are detected.
NEXT
