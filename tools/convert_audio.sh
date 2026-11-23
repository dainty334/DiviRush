#!/usr/bin/env bash
# Turns the downloaded CC0 audio into the game's sound files (D-018 and D-020 music, D-019 sound effects):
#   assets/audio/music/*.ogg  one loop for each area of the game and each Episode, and the win jingle
#   assets/audio/sfx/*.wav    tap, correct, wrong, time-up, Star and pop sounds
# It needs ffmpeg and unzip. Download the files below into one folder, then run from the project folder:
#   bash tools/convert_audio.sh <download folder>
# Sources (all CC0, public domain; credit is kind but not required), all from https://opengameart.org:
#   HappyClappyLoop.wav                "Happy Clappy Loop" by OwlishMedia         content/happy-clappy-loop          -> main_menu_loop.ogg
#   children_soundtrack_3.wav          "Children's Game Music 3 - Home" by heartade (Daniel Soohan Park)
#                                                                                 content/childrens-game-music-3-home   -> select_loop.ogg
#   children_soundtrack_1.wav          "Children's Game Music 1 - Picnic" by heartade
#                                                                                 content/childrens-game-music-1-picnic -> play_episode_1.ogg
#   ruskerdax_-_happy_vibes.mp3        "Happy Vibes" by Ruskerdax                 node/160228                        -> play_episode_2.ogg
#   cozy_puzzle_in-game_2_bpm90_0.ogg  "Cozy Puzzle In-Game 2" by MintoDog        node/185146                        -> play_episode_3.ogg
#   children_soundtrack_4.wav          "Children's Game Music 4 - Activity" by heartade
#                                                                                 content/childrens-game-music-4-activity -> play_episode_4.ogg
#   jingleSounds_Kenney.zip            "Music Jingles" by Kenney (www.kenney.nl)  content/85-short-music-jingles     -> win_jingle.ogg
#   kenney_interfaceSounds.zip         "Interface Sounds" by Kenney               content/interface-sounds           -> sfx/*.wav
set -euo pipefail  # Stop at the first error, and treat unset names as errors.

SRC="${1:?Give the folder with the downloaded files}"  # Folder with the downloaded files.
MUSIC_OUT="assets/audio/music"  # Where the game's music goes.
SFX_OUT="assets/audio/sfx"  # Where the game's sound effects go.
BLEND=1.5  # Seconds where the end of a fading track blends into its start, so the loop has no jump.
LOOP_LOUDNESS=-16.5  # Average loudness of every music loop in dB, so no track is much louder than another.
WORK="$(mktemp -d)"  # A scratch folder for in-between files.
trap 'rm -rf "$WORK"' EXIT  # Remove the scratch folder when the tool ends.

# ---------- Music (D-018, D-020) ----------

# Saves a prepared WAV as the game's OGG loop, at LOOP_LOUDNESS on average. The gain is limited so the
# loudest point stays below -1 dB, so a loud track is never pushed into crackling.
save_loop() {
  local wav="$1"  # The prepared loop.
  local out="$2"  # The OGG to write.
  local levels  # Its average and loudest levels.
  levels=$(ffmpeg -hide_banner -i "$wav" -af volumedetect -f null - 2>&1 | grep -oE "(mean|max)_volume: [-0-9.]+" | cut -d' ' -f2 | tr '\n' ' ')  # Measure them.
  local gain  # How much louder (or quieter) to make it.
  gain=$(echo "$levels" | awk -v t="$LOOP_LOUDNESS" '{ g = t - $1; if ($2 + g > -1) g = -1 - $2; printf "%.1f", g }')  # Reach the target, keeping 1 dB of headroom.
  ffmpeg -y -v error -i "$wav" -af "volume=${gain}dB" -c:a libvorbis -q:a 5 -ar 44100 "$out"  # Save as OGG.
  echo "saved $out (${gain} dB)"  # Report the file.
}

# Makes a smooth loop from a track that ends on a fading last note. Played as it is, the loop would
# jump from that quiet ending back to the start. Instead the loop is: the middle of the track, then its
# last BLEND seconds fading out while its first BLEND seconds fade in. Played again and again, every
# join is smooth. Both fades follow a quarter-sine curve, so the sound does not dip in the middle.
blend_loop() {
  local in="$1"  # The downloaded track.
  local out="$2"  # The OGG to write.
  local dur  # Length of the track in seconds.
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")  # Ask ffprobe for the length.
  local end  # Where the blended ending starts.
  end=$(awk -v d="$dur" -v b="$BLEND" 'BEGIN { print d - b }')  # The length minus the blend.
  # Cut the middle, the faded end and the faded start, mix end and start, and put them after the middle.
  ffmpeg -y -v error -i "$in" -filter_complex \
    "[0:a]atrim=${BLEND}:${end},asetpts=PTS-STARTPTS[mid];[0:a]atrim=start=${end},asetpts=PTS-STARTPTS,afade=t=out:d=${BLEND}:curve=qsin[tail];[0:a]atrim=0:${BLEND},asetpts=PTS-STARTPTS,afade=t=in:d=${BLEND}:curve=qsin[head];[tail][head]amix=inputs=2:normalize=0[join];[mid][join]concat=n=2:v=0:a=1[out]" \
    -map "[out]" -c:a pcm_f32le "$WORK/loop.wav"
  save_loop "$WORK/loop.wav" "$out"  # Set the loudness and save.
}

# Uses a track that its maker already made to loop without a gap, as it is. `trim` set to "trim"
# first removes near-silence at the very start (an MP3 adds a little), so the loop has no gap.
straight_loop() {
  local in="$1"  # The downloaded track.
  local out="$2"  # The OGG to write.
  local trim="${3:-}"  # "trim" to remove silence at the start.
  local filter="anull"  # By default, change nothing.
  if [ "$trim" = "trim" ]; then filter="silenceremove=start_periods=1:start_threshold=-50dB"; fi  # Or cut the silent start.
  ffmpeg -y -v error -i "$in" -af "$filter" -c:a pcm_f32le "$WORK/loop.wav"  # Prepare the loop.
  save_loop "$WORK/loop.wav" "$out"  # Set the loudness and save.
}

straight_loop "$SRC/HappyClappyLoop.wav" "$MUSIC_OUT/main_menu_loop.ogg"  # Main menu area: cheerful piano.
blend_loop "$SRC/children_soundtrack_3.wav" "$MUSIC_OUT/select_loop.ogg"  # Selection screens: calm piano, flute and strings.
blend_loop "$SRC/children_soundtrack_1.wav" "$MUSIC_OUT/play_episode_1.ogg"  # Episode 1 play: saxophone, vibraphone and strings.
straight_loop "$SRC/ruskerdax_-_happy_vibes.mp3" "$MUSIC_OUT/play_episode_2.ogg" trim  # Episode 2 play: cute island feel.
straight_loop "$SRC/cozy_puzzle_in-game_2_bpm90_0.ogg" "$MUSIC_OUT/play_episode_3.ogg"  # Episode 3 play: brass, 90 BPM.
blend_loop "$SRC/children_soundtrack_4.wav" "$MUSIC_OUT/play_episode_4.ogg"  # Episode 4 play: shakers and woodblocks.
# Short rising saxophone jingle, taken out of the zip and made 6 dB louder, so it is as loud as the loops.
unzip -p "$SRC/jingleSounds_Kenney.zip" "OGG/jingles_SAX/jingles_SAX02.ogg" | ffmpeg -y -v error -i pipe:0 -af volume=6dB -c:a libvorbis -q:a 5 -ar 44100 "$MUSIC_OUT/win_jingle.ogg"
echo "saved $MUSIC_OUT/win_jingle.ogg"  # Report the file.

# ---------- Sound effects (D-019) ----------

# Makes one sound effect: takes a Kenney sound out of the zip, sets its loudness, and saves it as a
# 16-bit mono WAV at 44100 samples per second (WAV starts with no delay, which suits short sounds).
# The loudness is moved to `target` dB on average (at most 12 dB louder). A limiter then holds the
# loudest points at -1 dB, so a sound with one sharp peak can still reach the target without crackling.
make_sfx() {
  local name="$1"  # The Kenney sound, for example select_002.
  local out="$2"  # The game file to write, for example tap.wav.
  local target="$3"  # The average loudness wanted, in dB.
  unzip -o -q -j "$SRC/kenney_interfaceSounds.zip" "Audio/$name.ogg" -d "$WORK"  # Take the sound out of the zip.
  local mean  # Its average loudness.
  mean=$(ffmpeg -hide_banner -i "$WORK/$name.ogg" -af volumedetect -f null - 2>&1 | grep -oE "mean_volume: [-0-9.]+" | cut -d' ' -f2)  # Measure it.
  local gain  # How much louder (or quieter) to make it.
  gain=$(awk -v t="$target" -v m="$mean" 'BEGIN { g = t - m; if (g > 12) g = 12; printf "%.1f", g }')  # Reach the target, at most 12 dB louder.
  # Change the loudness, hold the peaks at -1 dB (0.891) with a fast limiter, and save the game file.
  ffmpeg -y -v error -i "$WORK/$name.ogg" -af "volume=${gain}dB,alimiter=limit=0.891:attack=1:release=30:level=disabled" -ac 1 -ar 44100 -c:a pcm_s16le "$SFX_OUT/$out"
  echo "saved $SFX_OUT/$out from $name (${gain} dB)"  # Report the file.
}

make_sfx select_002 tap.wav -16  # Button tap: a short, soft click, quieter than the feedback sounds.
make_sfx confirmation_001 correct.wav -12  # Correct answer: a short rising, warm sound.
make_sfx error_006 wrong.wav -13  # Wrong answer: a low, gentle falling sound, not a harsh buzz.
make_sfx minimize_006 time_up.wav -13  # Timer ran out: a low falling swoosh, unlike the wrong sound.
make_sfx glass_001 star.wav -14  # A Star fills in: a glassy ring (the game raises its pitch for each Star).
make_sfx drop_002 pop.wav -15  # A bubble pops: a water-drop sound.
