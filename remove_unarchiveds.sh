#!/bin/bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

#######################################
# Archive check
#######################################
MAIN_ARCHIVE="$LOG_DIR/main_archive.txt"
ARCHIVES="$LOG_DIR/archive_*.txt"
if compgen -G "$ARCHIVES" > /dev/null; then
    echo "ERROR: Detected $ARCHIVES. Run gen_list.sh first to let them be appended to $MAIN_ARCHIVE and then deleted." >&2
    exit 1
fi

if [[ ! -f "$MAIN_ARCHIVE" ]]; then
    echo "$MAIN_ARCHIVE not found."
    exit 0
fi

sort -u -o "$MAIN_ARCHIVE" "$MAIN_ARCHIVE"
echo "Found $(wc -l < "$MAIN_ARCHIVE") IDs in $MAIN_ARCHIVE."

#######################################
# Save dir check
#######################################
FILES_FILE="$LOG_DIR/saved_files.txt"
find "$SAVE_DIR" -maxdepth 1 -type f -printf '%f\n' > "$FILES_FILE"
echo "$SAVE_DIR has $(wc -l < "$FILES_FILE") files. Saved to $FILES_FILE."

ID_FILE="$LOG_DIR/saved_IDs.txt"
grep -oP '\[\K[A-Za-z0-9_-]{11}(?=\]\.)' "$FILES_FILE" | sort -u > "$ID_FILE"
echo "Found $(wc -l < "$ID_FILE") IDs in $SAVE_DIR. Saved to $ID_FILE."

S_ID_FILE="$LOG_DIR/unsaved_IDs.txt"
comm -13 "$ID_FILE" "$MAIN_ARCHIVE" > "$S_ID_FILE"
UNSAVED_COUNT=$(wc -l < "$S_ID_FILE")
(( UNSAVED_COUNT > 0 )) && echo "WARNING: Found $UNSAVED_COUNT IDs in $MAIN_ARCHIVE but not in $SAVE_DIR. Saved to $S_ID_FILE." >&2

A_ID_FILE="$LOG_DIR/unarchived_IDs.txt"
comm -23 "$ID_FILE" "$MAIN_ARCHIVE" > "$A_ID_FILE"
UNARCHIVED_COUNT=$(wc -l < "$A_ID_FILE")
if (( UNARCHIVED_COUNT > 0 )); then
    echo "Found $UNARCHIVED_COUNT IDs in $SAVE_DIR but not in $MAIN_ARCHIVE. Saved to $A_ID_FILE."
else
    echo "All IDs in $SAVE_DIR are in $MAIN_ARCHIVE."
    exit 0
fi

#######################################
# Remove unarchiveds
#######################################
U_FILE="$LOG_DIR/unarchiveds.txt"
grep -Ff "$A_ID_FILE" "$FILES_FILE" > "$U_FILE"
while true; do
    echo "Found $(wc -l < "$U_FILE") unarchived files in $SAVE_DIR:"
    grep --color=always -Ff "$A_ID_FILE" "$U_FILE" | sed 's/^/    /'
    read -rp "Edit $U_FILE, then press [N] to reload, or press [y] to remove these files. " ans
    [[ $ans =~ ^[Yy]$ ]] && break
    echo "========================================================="
done

while IFS= read -r f
    do rm -- "$SAVE_DIR/$f"
done < "$U_FILE"
echo "Done."
