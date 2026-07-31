#!/bin/bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

#######################################
# Extra Config
#######################################
COLS=4
ROWS=2

yt_dlp_cmd() {
    printf -v pad_i "%02d" "$1"
    printf '%q ' yt-dlp \
        -f "bv*+ba/b/ba" \
        --embed-thumbnail \
        --embed-metadata \
        --cookies "$COOKIES" \
        -P "$SAVE_DIR" \
        -a "$LOG_DIR/list_$pad_i.txt" \
        --download-archive "$LOG_DIR/archive_$pad_i.txt"
}

WORKAREA=$(xprop -root _NET_WORKAREA | awk -F' = ' '{print $2}')
IFS=', ' read -r WA_X WA_Y WA_W WA_H <<< "$WORKAREA"

WIN_WIDTH=$((WA_W / COLS))
WIN_HEIGHT=$((WA_H / ROWS))

#######################################
# File check
#######################################

if [[ ! -f "$COOKIES" ]]; then
    echo "Error: Cookie file '$COOKIES' not found." >&2
    exit 1
fi

OK=true
for ((i=0; i<WORKERS; i++)); do
    printf -v pad_i "%02d" "$i"
    if [[ ! -f "$LOG_DIR/list_$pad_i.txt" ]]; then
        echo "Error: List file '$LOG_DIR/list_$pad_i.txt' not found." >&2
        OK=false
    fi
done
if [[ "$OK" != "true" ]]; then
    echo "Consider running gen_list.sh to generate these files." >&2
    exit 1
fi

count=$(find "$LOG_DIR" -maxdepth 1 -name 'list_*.txt' | wc -l)
if (( count > WORKERS )); then
    read -rp "Found $count list files. Continue? [y/N] " ans
    [[ $ans =~ ^[Yy]$ ]] || exit 1
fi

#######################################
# Spawn workers
#######################################
for ((i=0; i<WORKERS; i++)); do
    gnome-terminal --title="yt-dlp-$i" -- bash -c "$(yt_dlp_cmd "$i"); exec bash"
done

for ((i=0; i<WORKERS; i++)); do
    x_pos=$(( (i % COLS * WIN_WIDTH) + WA_X ))
    y_pos=$(( (i / COLS * WIN_HEIGHT) + WA_Y ))

    wmctrl -r "yt-dlp-$i" -b remove,maximized_vert,maximized_horz
    wmctrl -r "yt-dlp-$i" -e 0,$x_pos,$y_pos,$WIN_WIDTH,$WIN_HEIGHT
done

echo "Done."
