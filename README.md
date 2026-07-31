# `yt-dlp` Parallelization Script
As the name suggests, this is a script used to parallelize downloading playlist using `yt-dlp`, because `yt-dlp` hasn't support parallel downloads yet.

## Features
- Fetch and divide playlist into sublists.
- Launch a terminal to download each sublist.
- Tile the terminals so you can easily monitor each of them.
- Restore downloading jobs after an abrupt stop.

## Prerequisites
This script is for personal use so it isn't tested properly.
- Tested OS: Linux Mint Cinammon
- Dependency: `yt-dlp gnome-terminal wmctrl x11-utils coreutils`
- Optional: `Deno` for solving JS challenges, some VPN provider in case of being timed-out by YouTube backend (unlikely).

This script also need [cookies for `yt-dlp`](https://github.com/yt-dlp/yt-dlp/wiki/Extractors#exporting-youtube-cookies), but you can remove that quite easily i think (just ask AI). Note that if you don't provide cookies to `yt-dlp`, you are more likely to be timed-out by YouTube backend.

## Usages
You can probably skip these as the script will prints helpful messages to guide you.

### `config.sh`
Before using the scripts, check out `config.sh`, which includes these parameters:
- `WORKERS`: Number of sublists to be divided into and downloaded simultaneously.
- `YT_PLAYLIST_ID`: YouTube playlist ID. When a playlist's URL is `https://www.youtube.com/playlist?list=[id]`, then `[id]` is its ID. For example, [this playlist](https://www.youtube.com/playlist?list=PLuzAMsBVy2JkfoJerwuWIq4GkQnAUMX1N) has ID `PLuzAMsBVy2JkfoJerwuWIq4GkQnAUMX1N`.
- `COOKIES`: Directory to the cookies file.
- `SAVE_DIR`: Directory to save the videos.
- `LOG_DIR`: Directory to save logs. The logs will be used to restore downloading jobs after an abrupt stop.

### Main Usage
For a fresh start, run `gen_list.sh` to fetch the playlist and generate sublists, e.g. `$LOG_DIR/list_00.txt`, `$LOG_DIR/list_01.txt`, `$LOG_DIR/list_02.txt`, etc. Then run `run.sh` to spawn `$WORKERS` terminals, each downloads videos in `$LOG_DIR/list_[i].txt`. You can interrupt/close any of the terminals at any time, but if you want to run any script you have to stop other terminals too.

If some worker stops abruptly by **you**, **You**Tube, `yt-dlp`, or **you**r PC, close (not stop) all other workers too, then re-run `run.sh`. `yt-dlp` keeps track of downloaded videos in `$LOG_DIR/archive_[i].txt` and will skip them in the next run.

### `run.sh`
For my use case, I want to pass cookies to `yt-dlp` to reduce the chances of being rate-limited, hence `run.sh` exits if it can't find the cookie file. But I think anyone can easily read and modify `run.sh` to not require cookies.

`run.sh` also exits if it can't find `$LOG_DIR/list_[i].txt` for some worker `i`. To fix it just re-run `gen_list.sh`. It also warns you if there are more sublists than workers, meaning the extra sublists won't be downloaded. Again, just re-run `gen_list.sh` to fix that.

`run.sh` tiles windows **across the whole screen**, so I advise you to run it in a seperate workspace. A related fact IDK where else to mention is that, it identifies which window to be where by checking its title name.

### `gen_list.sh`
You can also re-generate sublists by running `gen_list.sh`. This will check the playlist, filter out videos already downloaded, then divide the remaining into sublists.
- Note that if `$LOG_DIR/$YT_PLAYLIST_ID.txt` exists, then that means the playlist is already fetched, and `gen_list.sh` will use this file instead. To re-fetch the playlist, delete the file.
- If files matching format `$LOG_DIR/archive_*.txt` exist, `gen_list.sh` will append them into `$LOG_DIR/main_archive.txt` and delete them. This is how `gen_list.sh` filter out videos already downloaded, it reads `$LOG_DIR/$YT_PLAYLIST_ID.txt` and remove entries that are in `$LOG_DIR/main_archive.txt`.

### `remove_unarchiveds.sh`
A download and processing of a video may fail during execution, leaving behind junk files and such. By common sense, these files should be cleaned/overwritten in the next run, but no no no my PC doesn't follow common senses. So I've written `remove_unarchiveds.sh` to fix this.

All files in `$SAVE_DIR` are expected to be in format `[Video Name] [Video ID].[ext]`. Junk files have compound extensions, e.g. `[Video Name] [Video ID].[ext].[ext2].[ext3].[...]`. Whatever the extension is, `remove_unarchiveds.sh` reads `$SAVE_DIR` and extract list of `[Video ID]` codes, then compare with `$LOG_DIR/main_archive.txt` to see which one is not marked as already downloaded, then remove files according to their `[Video ID]` codes.

It's a good idea to check what is going to be removed. For example, an old version of this script detected `AmaneKanata` in `UNDERTALE - Once Upon A Time (Acapella) [AmaneKanata] [8AGPo_j7WlA].mkv` as a video ID, and ask to remove the file because it couldn't find any video with ID `AmaneKanata`. Hence, I make this script prints all to-be-removed files, with highlight on what are detected as video IDs, and ask for user confirmation. When that happens, you can check `$LOG_DIR/unarchiveds.txt` and remove filenames you don't want to remove, then continue.

## Contributing
Want to contribute to this project? Or report a bug?\
Well you can't. idgaf, this is a scripting project for personal use. idek how you get here, there are already apps with way better features and UI/UX out there.
