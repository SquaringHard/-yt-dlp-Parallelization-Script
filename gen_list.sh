#!/bin/bash
shopt -s nullglob
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

#######################################
# Fetch playlist
#######################################
mkdir -p "$LOG_DIR"
PLAYLIST_FILE="$LOG_DIR/$YT_PLAYLIST_ID.txt"
if [[ -f "$PLAYLIST_FILE" ]]; then
    echo "Found $PLAYLIST_FILE. Use this file instead of re-fetching."
else
    URL="https://www.youtube.com/playlist?list=$YT_PLAYLIST_ID"
    echo "Fetching IDs in $URL to $PLAYLIST_FILE."
    yt-dlp --flat-playlist --get-id "$URL" > "$PLAYLIST_FILE"
fi

sort -u -o "$PLAYLIST_FILE" "$PLAYLIST_FILE"
echo "$PLAYLIST_FILE has $(wc -l < "$PLAYLIST_FILE") IDs."

#######################################
# Fetch saved archives
#######################################
MAIN_ARCHIVE="${LOG_DIR}/main_archive.txt"
ARCHIVES=( "$LOG_DIR"/archive_*.txt )

touch "$MAIN_ARCHIVE"
if ((${#ARCHIVES[@]})); then
    echo "These files will be appended to $MAIN_ARCHIVE and then deleted:"
    for files in "${ARCHIVES[@]}"; do
        echo "    $files"
    done
    sed 's/^youtube //' "${ARCHIVES[@]}" >> "$MAIN_ARCHIVE"
    rm "${ARCHIVES[@]}"
fi

sort -u -o "$MAIN_ARCHIVE" "$MAIN_ARCHIVE"
echo "$MAIN_ARCHIVE has $(wc -l < "$MAIN_ARCHIVE") IDs."

EXTRA_LOG="${LOG_DIR}/extras.txt"
comm -13 "$PLAYLIST_FILE" "$MAIN_ARCHIVE" > "$EXTRA_LOG"
EXTRA_COUNT=$(wc -l < "$EXTRA_LOG")
if (( EXTRA_COUNT > 0 )); then
    echo "WARNING: Found $EXTRA_COUNT IDs in $MAIN_ARCHIVE that are not in $PLAYLIST_FILE. Saved to $EXTRA_LOG." >&2
fi

#######################################
# Create lists
#######################################
MAIN_LIST="${LOG_DIR}/main_list.txt"
echo "Writing IDs in $PLAYLIST_FILE that arent in $MAIN_ARCHIVE, into $MAIN_LIST."
comm -23 "$PLAYLIST_FILE" "$MAIN_ARCHIVE" > "$MAIN_LIST"

MAIN_LIST_COUNT=$(wc -l < "$MAIN_LIST")
echo "$MAIN_LIST has $MAIN_LIST_COUNT IDs."
(( MAIN_LIST_COUNT > 0 )) || exit 0

echo "Removing ${LOG_DIR}/list_*.txt."
rm -f "$LOG_DIR"/list_*.txt

echo "Splitting $MAIN_LIST into $WORKERS files."
sed 's|^|https://www.youtube.com/watch?v=|' "$MAIN_LIST" | split -l $(( (MAIN_LIST_COUNT + WORKERS - 1) / WORKERS )) -d -a 2 --additional-suffix=.txt - "$LOG_DIR/list_"
echo "Done."
